#!/usr/bin/env python3
"""
Kafka Message Downloader - Compact Version
Downloads messages from Kafka topics with SASL/SSL support and time filtering.
Handles FlatBuffers binary data automatically.
"""

from kafka import KafkaConsumer
import json
import argparse
import base64
import gzip
import pickle
from datetime import datetime
from kafka import TopicPartition


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


class KafkaMessageDownloader:
    """Downloads messages from Kafka with authentication and filtering support"""
    
    def __init__(self, brokers, topic, group_id=None, kafka_config=None):
        # Base consumer config
        config = {
            'bootstrap_servers': brokers.split(','),
            'auto_offset_reset': 'earliest',
            'enable_auto_commit': False,
            'consumer_timeout_ms': 10000,
            'key_deserializer': None,
            'value_deserializer': None,
            'max_partition_fetch_bytes': 1024*1024
        }
        
        if group_id:
            config['group_id'] = group_id
        
        # Apply Kafka config (consumer-specific mappings)
        if kafka_config:
            mappings = {
                'message.max.bytes': 'max_partition_fetch_bytes',
                'fetch.message.max.bytes': 'fetch_max_bytes',
                'security.protocol': 'security_protocol',
                'sasl.mechanism': 'sasl_mechanism', 
                'sasl.username': 'sasl_plain_username',
                'sasl.password': 'sasl_plain_password',
                'ssl.ca.location': 'ssl_cafile',
                'ssl.certificate.location': 'ssl_certfile',
                'ssl.key.location': 'ssl_keyfile',
                'ssl.key.password': 'ssl_password',
                'ssl.check.hostname': 'ssl_check_hostname'
            }
            
            # Skip producer-only configs
            skip = {'statistics.interval.ms', 'message.timeout.ms', 'queue.buffering.max.ms', 'message.copy.max.bytes'}
            
            for key, value in kafka_config.items():
                if key not in skip and key in mappings:
                    config[mappings[key]] = value
        
        self.topic = topic
        self.consumer = KafkaConsumer(topic, **config)
    
    def _seek_to_timestamp(self, start_time_ms=None, end_time_ms=None):
        """Seek consumer to specific timestamp positions"""
        if not start_time_ms:
            return
            
        # Get all partitions for the topic
        partitions = self.consumer.partitions_for_topic(self.topic)
        if not partitions:
            print("No partitions found for topic")
            return
            
        # Create timestamp dictionary for all partitions
        timestamp_dict = {}
        for partition in partitions:
            topic_partition = TopicPartition(self.topic, partition)
            timestamp_dict[topic_partition] = start_time_ms
        
        # Get offsets for timestamps
        offset_dict = self.consumer.offsets_for_times(timestamp_dict)
        
        # Seek to the appropriate offsets
        for topic_partition, offset_timestamp in offset_dict.items():
            if offset_timestamp is not None:
                self.consumer.seek(topic_partition, offset_timestamp.offset)
                print(f"Seeking partition {topic_partition.partition} to offset {offset_timestamp.offset} (timestamp: {offset_timestamp.timestamp})")
            else:
                print(f"No messages found after start time in partition {topic_partition.partition}")
    
    def download_to_json(self, output_file, max_messages=None, start_time_ms=None, end_time_ms=None):
        """Download messages as JSON Lines format with optional time filtering"""
        # Seek to start timestamp if provided
        self._seek_to_timestamp(start_time_ms, end_time_ms)
        
        count = skipped = 0
        
        with open(output_file, 'w') as f:
            for message in self.consumer:
                try:
                    # Only need to filter end time now (start time handled by seeking)
                    if end_time_ms and message.timestamp > end_time_ms:
                        print("Reached end time, stopping...")
                        break
                    
                    # Handle binary data (FlatBuffers) - encode as base64
                    key_data = base64.b64encode(message.key).decode('utf-8') if message.key else None
                    value_data = base64.b64encode(message.value).decode('utf-8') if message.value else None
                    
                    record = {
                        'timestamp': message.timestamp,
                        'timestamp_iso': datetime.fromtimestamp(message.timestamp/1000).isoformat(),
                        'partition': message.partition,
                        'offset': message.offset,
                        'key': key_data,
                        'value': value_data,
                        'key_is_binary': message.key is not None,
                        'value_is_binary': message.value is not None,
                        'headers': {k: v.decode('utf-8', errors='ignore') if v else None 
                                  for k, v in (message.headers or [])}
                    }
                    
                    f.write(json.dumps(record) + '\n')
                    f.flush()
                    
                    count += 1
                    if count % 1000 == 0:
                        print(f"Downloaded {count} messages...")
                    
                    if max_messages and count >= max_messages:
                        break
                        
                except Exception as e:
                    print(f"Error processing message: {e}")
                    continue
        
        print(f"Downloaded {count} messages to {output_file}")
    
    def download_to_binary(self, output_file, compress=True, start_time_ms=None, end_time_ms=None):
        """Download messages in binary format for faster processing"""
        # Seek to start timestamp if provided
        self._seek_to_timestamp(start_time_ms, end_time_ms)
        
        count = skipped = 0
        opener = gzip.open if compress else open
        
        with opener(output_file, 'wb') as f:
            for message in self.consumer:
                try:
                    # Only need to filter end time now (start time handled by seeking)
                    if end_time_ms and message.timestamp > end_time_ms:
                        print("Reached end time, stopping...")
                        break
                    
                    record = {
                        'timestamp': message.timestamp,
                        'partition': message.partition,
                        'offset': message.offset,
                        'key': message.key,
                        'value': message.value,
                        'headers': dict(message.headers or [])
                    }
                    pickle.dump(record, f)
                    count += 1
                    
                    if count % 1000 == 0:
                        print(f"Downloaded {count} messages...")
                        
                except Exception as e:
                    print(f"Error processing message: {e}")
                    continue
        
        print(f"Downloaded {count} messages to {output_file}")


def main():
    parser = argparse.ArgumentParser(description='Download Kafka messages with authentication and time filtering')
    parser.add_argument('--brokers', required=True, help='Kafka bootstrap servers (comma-separated)')
    parser.add_argument('--topic', required=True, help='Topic to consume from')
    parser.add_argument('--group-id', help='Consumer group ID')
    parser.add_argument('--format', choices=['json', 'binary'], default='json', help='Output format')
    parser.add_argument('--output', required=True, help='Output file')
    parser.add_argument('--max-messages', type=int, help='Maximum messages to download')
    parser.add_argument('--compress', action='store_true', help='Compress binary output')
    parser.add_argument('--start-time', help='Start time (ISO format: YYYY-MM-DDTHH:MM:SS or YYYY-MM-DD)')
    parser.add_argument('--end-time', help='End time (ISO format: YYYY-MM-DDTHH:MM:SS or YYYY-MM-DD)')
    parser.add_argument('--kafka-config', help='Kafka configuration file (JSON format)')
    
    args = parser.parse_args()
    
    # Auto-append .gz extension when compress flag is used
    output_file = args.output
    if args.compress and not output_file.endswith('.gz'):
        output_file += '.gz'
        print(f"Compression enabled, output file changed to: {output_file}")
    
    # Load Kafka configuration
    kafka_config = None
    if args.kafka_config:
        try:
            kafka_config = load_kafka_config(args.kafka_config)
            print(f"Loaded Kafka configuration from {args.kafka_config}")
        except Exception as e:
            print(f"Error loading config: {e}")
            return 1
    
    # Parse time arguments
    start_time_ms = end_time_ms = None
    try:
        if args.start_time:
            start_time_ms = parse_timestamp(args.start_time)
            print(f"Start time: {args.start_time} ({start_time_ms})")
        if args.end_time:
            end_time_ms = parse_timestamp(args.end_time)
            print(f"End time: {args.end_time} ({end_time_ms})")
        if start_time_ms and end_time_ms and start_time_ms > end_time_ms:
            raise ValueError("Start time must be before end time")
    except ValueError as e:
        print(f"Time parsing error: {e}")
        return 1
    
    # Download messages
    downloader = KafkaMessageDownloader(args.brokers, args.topic, args.group_id, kafka_config)
    
    if args.format == 'json':
        downloader.download_to_json(output_file, args.max_messages, start_time_ms, end_time_ms)
    elif args.format == 'binary':
        downloader.download_to_binary(output_file, args.compress, start_time_ms, end_time_ms)


if __name__ == "__main__":
    main()
