#!/usr/bin/env python3
"""
Kafka Message Downloader - Compact Version
Downloads messages from Kafka topics with SASL/SSL support and time filtering.
Handles FlatBuffers binary data automatically with automatic parallel compression.
"""

from confluent_kafka import Consumer, TopicPartition, KafkaError, KafkaException
import json
import argparse
import base64
import gzip
import pickle
import os
import time
from datetime import datetime

# Try to import zstandard for parallel compression
try:
    import zstandard as zstd
    HAS_ZSTD = True
except ImportError:
    HAS_ZSTD = False

def parse_timestamp(time_str):
    """Convert ISO timestamp to milliseconds since epoch"""
    if not time_str:
        return None
    # Add midnight if only date provided
    if 'T' not in time_str:
        time_str += 'T00:00:00'
    return int(datetime.fromisoformat(time_str.replace('Z', '+00:00')).timestamp() * 1000)

def load_kafka_config(config_path):
    """Load and process Kafka configuration from JSON file"""
    with open(config_path, 'r') as f:
        config_data = json.load(f)
    
    # Flatten KafkaParms list to dict and convert types
    kafka_config = {}
    for param in config_data.get('KafkaParms', []):
        kafka_config.update(param)
    
    # Convert numeric strings and booleans
    processed = {}
    for key, value in kafka_config.items():
        if key.endswith(('.ms', '.bytes')) or key in ['retries', 'batch.size']:
            processed[key] = int(value) if str(value).isdigit() else value
        elif str(value).lower() in ['true', 'false']:
            processed[key] = str(value).lower() == 'true'
        else:
            processed[key] = value
    return processed

def get_compressor(output_file, compress=True):
    """Get the fastest compressor with true parallel compression when available"""
    if not compress:
        return open(output_file, 'wb'), "no compression"
    
    # Use Zstandard with medium compression and all cores - 1
    if HAS_ZSTD:
        threads = max(1, os.cpu_count() - 1) if os.cpu_count() > 1 else 1
        cctx = zstd.ZstdCompressor(
            level=6,  # Medium compression (good balance of speed and size)
            threads=threads,  # Use all cores - 1
            write_checksum=True
        )
        compressor = cctx.stream_writer(open(output_file, 'wb'))
        return compressor, f"Zstandard parallel compression using {threads} threads (level 6)"
    
    # Fallback to gzip if Zstandard not available
    else:
        compressor = gzip.open(output_file, 'wb', compresslevel=6)
        return compressor, "Gzip compression (single-threaded fallback, level 6)"

class KafkaMessageDownloader:
    """Downloads messages from Kafka with authentication and filtering support"""
    
    def __init__(self, brokers, topic, group_id=None, kafka_config=None):
        self.topic = topic
        self._create_consumer(brokers, group_id, kafka_config)
    
    def _create_consumer(self, brokers, group_id, kafka_config):
        """Create and test Kafka consumer connection"""
        # Base consumer config for confluent-kafka
        config = {
            'bootstrap.servers': brokers if isinstance(brokers, str) else ','.join(brokers),
            'auto.offset.reset': 'earliest',
            'enable.auto.commit': False,
        }
        
        if group_id:
            config['group.id'] = group_id
        
        # Apply Kafka config (confluent-kafka uses librdkafka config names directly)
        if kafka_config:
            self._apply_kafka_config(config, kafka_config)
        
        try:
            self.consumer = Consumer(config)
            # Test the connection by trying to get partition info
            metadata = self.consumer.list_topics(self.topic, timeout=10)
            if self.topic not in metadata.topics:
                raise KafkaException(f"Topic '{self.topic}' not found or no access permissions")
        except KafkaException as e:
            self._handle_consumer_error(e, brokers)
        except Exception as e:
            raise Exception(f"Failed to initialize Kafka consumer: {str(e)}")
    
    def _apply_kafka_config(self, config, kafka_config):
        """Apply Kafka configuration to consumer config"""
        # Most configs can be passed directly to confluent-kafka
        direct_configs = {
            'message.max.bytes', 'fetch.message.max.bytes', 'security.protocol',
            'sasl.mechanism', 'sasl.username', 'sasl.password', 'ssl.ca.location',
            'ssl.certificate.location', 'ssl.key.location', 'ssl.key.password',
            'ssl.check.hostname'
        }
        
        # Skip producer-only configs
        skip = {'statistics.interval.ms', 'message.timeout.ms', 'queue.buffering.max.ms', 'message.copy.max.bytes'}
        
        for key, value in kafka_config.items():
            if key not in skip and key in direct_configs:
                config[key] = value
    
    def _handle_consumer_error(self, e, brokers):
        """Handle consumer creation errors with specific messages"""
        error_str = str(e).lower()
        if "authentication" in error_str or "sasl" in error_str:
            raise Exception(f"Authentication failed: {str(e)}. Check your credentials in the Kafka config.")
        elif "ssl" in error_str:
            raise Exception(f"SSL/TLS connection failed: {str(e)}. Check your SSL configuration.")
        elif "broker" in error_str or "connection" in error_str:
            raise Exception(f"Failed to connect to Kafka brokers: {brokers}. Check if brokers are running and accessible.")
        else:
            raise Exception(f"Failed to initialize Kafka consumer: {str(e)}")

    def _seek_to_timestamp(self, start_time_ms=None, end_time_ms=None):
        """Seek consumer to specific timestamp positions"""
        if not start_time_ms:
            return False  # Return False to indicate no seeking was done
            
        # Get all partitions for the topic
        metadata = self.consumer.list_topics(self.topic, timeout=10)
        partitions = list(metadata.topics[self.topic].partitions.keys())
        
        if not partitions:
            print("No partitions found for topic")
            return False
            
        # Create TopicPartition objects for all partitions (without offset)
        topic_partitions = [TopicPartition(self.topic, p) for p in partitions]
        
        # Assign partitions to consumer
        self.consumer.assign(topic_partitions)
        
        # For confluent-kafka, offsets_for_times expects TopicPartitions 
        # with timestamps in the offset field
        timestamp_partitions = [TopicPartition(self.topic, p, start_time_ms) for p in partitions]
        
        # Get offsets for timestamps
        seeking_successful = False
        try:
            offset_results = self.consumer.offsets_for_times(timestamp_partitions, timeout=10)
            
            # Seek to the appropriate offsets
            for result in offset_results:
                if result and result.offset >= 0:
                    self.consumer.seek(result)
                    print(f"Seeking partition {result.partition} to offset {result.offset}")
                    seeking_successful = True
                elif result:
                    print(f"No messages found after start time in partition {result.partition}")
                    
        except Exception as e:
            print(f"Error seeking to timestamp: {e}")
            # Fallback: just assign partitions and start from beginning
            self.consumer.assign(topic_partitions)
            return False
            
        return seeking_successful

    def _process_messages(self, start_time_ms, end_time_ms, seeking_successful, message_processor, max_messages=None, flush_func=None):
        """Common message processing loop for both JSON and binary formats"""
        count = 0
        messages_in_timeframe = 0
        empty_polls = 0
        messages_before_timeframe = 0
        
        # Reduce timeout when seeking failed and we have a time window
        max_empty_polls = 10 if start_time_ms and not seeking_successful else 30  # Much more reasonable timeout
        max_messages_before_timeout = 1000  # Stop if we see too many messages before timeframe
        
        try:
            while True:
                msg = self.consumer.poll(timeout=1.0)
                if msg is None:
                    empty_polls += 1
                    if empty_polls >= max_empty_polls:
                        if messages_in_timeframe == 0 and (start_time_ms or end_time_ms):
                            print(f"No messages found in specified time window. Stopping after {max_empty_polls} empty polls...")
                        else:
                            print(f"No more messages after {max_empty_polls} empty polls. Stopping...")
                        break
                    continue
                
                empty_polls = 0  # Reset counter when we get a message
                    
                if msg.error():
                    if msg.error().code() == KafkaError._PARTITION_EOF:
                        # End of partition, continue polling but count as empty
                        empty_polls += 1
                        if empty_polls >= max_empty_polls:
                            print(f"Reached end of all partitions after {max_empty_polls} consecutive EOF. Stopping...")
                            break
                        continue
                    else:
                        print(f'Consumer error: {msg.error()}')
                        break
                
                # Filter by time window (both start and end time)
                msg_timestamp = msg.timestamp()[1]
                
                # Skip messages before start time (when seeking failed)
                if start_time_ms and not seeking_successful and msg_timestamp < start_time_ms:
                    messages_before_timeframe += 1
                    # If we're seeing lots of messages before our timeframe, probably no messages in window
                    if messages_before_timeframe > max_messages_before_timeout:
                        print(f"Processed {messages_before_timeframe} messages before timeframe with none in target window. Likely no messages exist in specified time range. Stopping...")
                        break
                    continue
                
                # Stop when we reach the end time
                if end_time_ms and msg_timestamp > end_time_ms:
                    print("Reached end time, stopping...")
                    break
                
                # Count messages in our time frame
                messages_in_timeframe += 1
                
                # Process the message using the provided processor function
                message_processor(msg, msg_timestamp)
                count += 1
                
                # Check for max message limit
                if max_messages and count >= max_messages:
                    print(f"Reached max message limit of {max_messages}")
                    break
                
                # Flush output periodically
                if flush_func and count % 1000 == 0:
                    flush_func()
                    print(f"Downloaded {count} messages...")
        
        except KeyboardInterrupt:
            print(f"\nDownload interrupted by user. Downloaded {count} messages.")
        finally:
            self.consumer.close()
            
        return count
    
    def download_to_json(self, output_file, max_messages=None, start_time_ms=None, end_time_ms=None, compress=True):
        """Download messages as JSON Lines format with automatic compression"""
        
        # Check for invalid compression + JSON combination
        if compress and (output_file.endswith('.json') or output_file.endswith('.jsonl')):
            print("Error: JSON format does not support compression. Use --no-compression or change to binary format.")
            return 1
        
        seeking_successful = self._seek_to_timestamp(start_time_ms, end_time_ms)
        
        if not seeking_successful and not start_time_ms:
            # No time constraints, use subscription approach
            self.consumer.subscribe([self.topic])
            
            # Wait for partition assignment (important for consumer groups)
            print("Waiting for partition assignment...")
            import time
            assignment_timeout = 10  # seconds
            start_time = time.time()
            
            while time.time() - start_time < assignment_timeout:
                assignment = self.consumer.assignment()
                if assignment:
                    print(f"Assigned to partitions: {[tp.partition for tp in assignment]}")
                    break
                self.consumer.poll(0.1)  # This triggers partition assignment
            else:
                print("Warning: No partition assignment received within timeout")
        
        compressor, compression_info = get_compressor(output_file, compress)
        print(f"Using {compression_info}")
        
        def json_message_processor(msg, msg_timestamp):
            try:
                # Handle binary data (FlatBuffers) - encode as base64
                key_data = msg.key()
                value_data = msg.value()
                
                key_is_binary = key_data and not isinstance(key_data, (str, type(None)))
                value_is_binary = value_data and not isinstance(value_data, (str, type(None)))
                
                # Convert key
                if key_is_binary:
                    key_str = base64.b64encode(key_data).decode('ascii')
                else:
                    key_str = key_data.decode('utf-8') if key_data else None
                
                # Convert value
                if value_is_binary:
                    value_str = base64.b64encode(value_data).decode('ascii')
                else:
                    value_str = value_data.decode('utf-8') if value_data else None
                
                # Create record
                record = {
                    'topic': msg.topic(),
                    'partition': msg.partition(),
                    'offset': msg.offset(),
                    'timestamp': msg_timestamp,
                    'key': key_str,
                    'value': value_str,
                    'key_is_binary': key_is_binary,
                    'value_is_binary': value_is_binary
                }
                
                # Write JSON line
                compressor.write(json.dumps(record).encode('utf-8') + b'\n')
                
            except Exception as e:
                print(f"Error processing message: {e}")
        
        def flush_compressor():
            if hasattr(compressor, 'flush'):
                compressor.flush()
        
        with compressor:
            count = self._process_messages(start_time_ms, end_time_ms, seeking_successful, 
                                         json_message_processor, max_messages, flush_compressor)
        
        print(f"Downloaded {count} messages to {output_file}")
        return count
    
    def download_to_binary(self, output_file, max_messages=None, start_time_ms=None, end_time_ms=None, compress=True):
        """Download messages in binary format with automatic compression"""
        seeking_successful = self._seek_to_timestamp(start_time_ms, end_time_ms)
        
        if not seeking_successful and not start_time_ms:
            # No time constraints, use subscription approach
            self.consumer.subscribe([self.topic])
            
            # Wait for partition assignment (important for consumer groups)
            print("Waiting for partition assignment...")
            import time
            assignment_timeout = 10  # seconds
            start_time = time.time()
            
            while time.time() - start_time < assignment_timeout:
                assignment = self.consumer.assignment()
                if assignment:
                    print(f"Assigned to partitions: {[tp.partition for tp in assignment]}")
                    break
                self.consumer.poll(0.1)  # This triggers partition assignment
            else:
                print("Warning: No partition assignment received within timeout")
        
        compressor, compression_info = get_compressor(output_file, compress)
        print(f"Using {compression_info}")
        
        def binary_message_processor(msg, msg_timestamp):
            try:
                # Store message data in pickle format
                record = {
                    'topic': msg.topic(),
                    'partition': msg.partition(),
                    'offset': msg.offset(),
                    'timestamp': msg_timestamp,
                    'key': msg.key(),
                    'value': msg.value(),
                    'headers': dict(msg.headers() or [])
                }
                
                # Use pickle to serialize
                pickle.dump(record, compressor)
                
            except Exception as e:
                print(f"Error processing message: {e}")
        
        def flush_compressor():
            if hasattr(compressor, 'flush'):
                compressor.flush()
        
        with compressor:
            count = self._process_messages(start_time_ms, end_time_ms, seeking_successful, 
                                         binary_message_processor, max_messages, flush_compressor)
        
        print(f"Downloaded {count} messages to {output_file}")
        return count


def main():
    parser = argparse.ArgumentParser(description='Download Kafka messages with authentication and time filtering')
    parser.add_argument('--brokers', required=True, help='Kafka bootstrap servers (comma-separated)')
    parser.add_argument('--topic', required=True, help='Topic to consume from')
    parser.add_argument('--group-id', help='Consumer group ID')
    parser.add_argument('--format', choices=['json', 'binary'], default='json', help='Output format')
    parser.add_argument('--output', required=True, help='Output file')
    parser.add_argument('--max-messages', type=int, help='Maximum messages to download')
    parser.add_argument('--compression', action='store_true', help='Enable compression')
    parser.add_argument('--start-time', help='Start time (ISO format: YYYY-MM-DDTHH:MM:SS or YYYY-MM-DD)')
    parser.add_argument('--end-time', help='End time (ISO format: YYYY-MM-DDTHH:MM:SS or YYYY-MM-DD)')
    parser.add_argument('--kafka-config', help='Kafka configuration file (JSON format)')
    
    args = parser.parse_args()
    
    # Validate JSON + compression combination
    if args.format == 'json' and args.compression:
        print("Error: JSON format does not support compression. Use binary format for compression or remove --compression flag.")
        return 1
    
    # Show compression library status for supported file types
    if not HAS_ZSTD and (args.output.endswith('.zst')):
        print("Error: File has .zst extension but zstandard library not installed.")
        print("Install with: pip install zstandard")
        return 1
    
    # Parse timestamps
    start_time_ms = parse_timestamp(args.start_time) if args.start_time else None
    end_time_ms = parse_timestamp(args.end_time) if args.end_time else None
    
    # Load Kafka configuration
    kafka_config = None
    if args.kafka_config:
        try:
            kafka_config = load_kafka_config(args.kafka_config)
            print(f"Loaded Kafka configuration from {args.kafka_config}")
        except Exception as e:
            print(f"Error loading config: {e}")
            return 1
    
    # Create downloader and download
    downloader = KafkaMessageDownloader(args.brokers, args.topic, args.group_id, kafka_config)
    
    try:
        # Determine compression based on format and flag
        use_compression = args.compression if args.format == 'binary' else False
        
        if args.format == 'json':
            downloader.download_to_json(args.output, args.max_messages, start_time_ms, end_time_ms, use_compression)
        elif args.format == 'binary':
            downloader.download_to_binary(args.output, args.max_messages, start_time_ms, end_time_ms, use_compression)
    except KeyboardInterrupt:
        print("\nDownload interrupted by user")
    except Exception as e:
        print(f"Download failed: {e}")
        return 1


if __name__ == "__main__":
    main()
