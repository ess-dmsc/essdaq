#!/usr/bin/env python3
"""
Kafka Message Uploader - Compact Version
Uploads previously downloaded Kafka messages with SASL/SSL support.
Preserves timestamps by default and handles binary FlatBuffers data.
"""

from confluent_kafka import Producer
import json
import argparse
import base64
import gzip
import pickle
import time
from datetime import datetime

# Try to import zstandard for decompression
try:
    import zstandard as zstd
    HAS_ZSTD = True
except ImportError:
    HAS_ZSTD = False


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


def get_decompressor(input_file):
    """Get the appropriate decompressor based on file extension"""
    if input_file.endswith('.zst'):
        if HAS_ZSTD:
            dctx = zstd.ZstdDecompressor()
            return dctx.stream_reader(open(input_file, 'rb')), "Zstandard decompression"
        else:
            raise ValueError("File has .zst extension but zstandard library not installed. Install with: pip install zstandard")
    elif input_file.endswith('.gz'):
        return gzip.open(input_file, 'rb'), "Gzip decompression"
    else:
        return open(input_file, 'rb'), "no decompression"


class KafkaMessageUploader:
    """Uploads messages to Kafka with authentication and timestamp preservation"""
    
    def __init__(self, brokers, preserve_timestamps=True, kafka_config=None):
        self.preserve_timestamps = preserve_timestamps
        
        # Base producer config for confluent-kafka
        config = {
            'bootstrap.servers': brokers if isinstance(brokers, str) else ','.join(brokers),
            'acks': 'all',
            'retries': 3,
            'batch.size': 16384,
            'linger.ms': 10,
            'queue.buffering.max.kbytes': 32768,  # confluent-kafka equivalent of buffer.memory
        }
        
        # Apply Kafka config (confluent-kafka uses librdkafka config names directly)
        if kafka_config:
            self._apply_kafka_config(config, kafka_config)
        
        # Create producer with delivery callback
        self.producer = Producer(config)
        self.delivery_callback = self._delivery_callback
    
    def _apply_kafka_config(self, config, kafka_config):
        """Apply Kafka configuration to producer config"""
        # Most configs can be passed directly to confluent-kafka
        direct_configs = {
            'message.max.bytes', 'message.timeout.ms', 'queue.buffering.max.ms',
            'batch.size', 'retries', 'security.protocol', 'sasl.mechanism',
            'sasl.username', 'sasl.password', 'ssl.ca.location',
            'ssl.certificate.location', 'ssl.key.location', 'ssl.key.password',
            'ssl.check.hostname'
        }
        
        # Skip consumer-only configs
        skip = {'fetch.message.max.bytes', 'statistics.interval.ms', 'api.version.request', 'message.copy.max.bytes'}
        
        for key, value in kafka_config.items():
            if key not in skip and key in direct_configs:
                config[key] = value
    
    def _delivery_callback(self, err, msg):
        """Delivery callback for producer"""
        if err:
            print(f'Message delivery failed: {err}')
        # Silent on success to avoid spam
    
    def _process_upload(self, input_file, target_topic, message_loader):
        """Common upload processing for both JSON and binary formats"""
        count = errors = 0
        
        decompressor, decomp_info = get_decompressor(input_file)
        print(f"Using {decomp_info}")
        
        with decompressor as f:
            try:
                for record in message_loader(f):
                    try:
                        # Extract message components
                        key, value, timestamp_ms, partition = self._extract_message_data(record)
                        
                        # Prepare producer call arguments
                        produce_args = {
                            'topic': target_topic,
                            'key': key,
                            'value': value,
                            'callback': self.delivery_callback
                        }
                        
                        # Only add partition if it's not None
                        if partition is not None:
                            produce_args['partition'] = partition
                            
                        # Only add timestamp if it's not None and we're preserving timestamps
                        if timestamp_ms is not None and self.preserve_timestamps:
                            if isinstance(timestamp_ms, str):
                                # Convert ISO timestamp to milliseconds since epoch
                                try:
                                    # Add midnight if only date provided
                                    if 'T' not in timestamp_ms:
                                        timestamp_ms += 'T00:00:00'
                                    timestamp_ms = int(datetime.fromisoformat(timestamp_ms.replace('Z', '+00:00')).timestamp() * 1000)
                                except (ValueError, AttributeError) as e:
                                    print(f"Warning: Could not parse timestamp '{timestamp_ms}': {e}")
                                    timestamp_ms = None
                            
                            if timestamp_ms is not None:
                                produce_args['timestamp'] = timestamp_ms
                        
                        # Send message using confluent-kafka
                        self.producer.produce(**produce_args)
                        
                        count += 1
                        if count % 1000 == 0:
                            print(f"Uploaded {count} messages...")
                            self.producer.flush()
                            
                    except Exception as e:
                        print(f"Error processing message: {e}")
                        errors += 1
                        
            except Exception as e:
                print(f"Error reading file: {e}")
                errors += 1
        
        # Final flush and status
        self.producer.flush()
        print(f"Upload completed: {count} messages sent, {errors} errors")
        
        return count, errors
    
    def _extract_message_data(self, record):
        """Extract message components from record (to be overridden by format-specific logic)"""
        raise NotImplementedError("Subclasses must implement _extract_message_data")
    
    def upload_from_jsonl(self, jsonl_file, target_topic):
        """Upload messages from JSON Lines format"""
        
        def json_loader(f):
            # For text mode, wrap binary streams
            if hasattr(f, 'mode') and 'b' in str(f.mode):
                import io
                f = io.TextIOWrapper(f, encoding='utf-8')
            
            for line_num, line in enumerate(f, 1):
                try:
                    record = json.loads(line.strip())
                    yield record
                except Exception as e:
                    print(f"Error on line {line_num}: {e}")
        
        def extract_json_message_data(record):
            # Extract and decode binary data
            key = record.get('key')
            if key and record.get('key_is_binary', False):
                key = base64.b64decode(key)
            elif key:
                key = key.encode('utf-8')
            
            value = record.get('value')
            if value and record.get('value_is_binary', False):
                value = base64.b64decode(value)
            elif value:
                value = value.encode('utf-8')
            
            # Handle timestamp preservation
            timestamp_ms = record.get('timestamp')
            partition = record.get('partition')
            
            return key, value, timestamp_ms, partition
        
        # Temporarily override the extract method for JSON processing
        original_extract = self._extract_message_data
        self._extract_message_data = extract_json_message_data
        
        try:
            return self._process_upload(jsonl_file, target_topic, json_loader)
        finally:
            self._extract_message_data = original_extract
    
    def upload_from_binary(self, binary_file, target_topic):
        """Upload messages from binary pickle format"""
        
        def pickle_loader(f):
            while True:
                try:
                    record = pickle.load(f)
                    yield record
                except EOFError:
                    break
                except Exception as e:
                    print(f"Error loading pickle data: {e}")
                    break
        
        def extract_binary_message_data(record):
            # Binary format keys and values are already bytes
            key = record.get('key')
            value = record.get('value')
            timestamp_ms = record.get('timestamp')
            partition = record.get('partition')
            
            return key, value, timestamp_ms, partition
        
        # Temporarily override the extract method for binary processing
        original_extract = self._extract_message_data
        self._extract_message_data = extract_binary_message_data
        
        try:
            return self._process_upload(binary_file, target_topic, pickle_loader)
        finally:
            self._extract_message_data = original_extract
    
    def batch_upload_with_rate_limit(self, input_file, target_topic, rate_limit, format_type='json'):
        """Upload with rate limiting (messages per second)"""
        print(f"Rate limiting to {rate_limit} messages/second")
        delay = 1.0 / rate_limit
        
        # Monkey patch the send method to add delay
        original_send = self.producer.send
        def rate_limited_send(*args, **kwargs):
            time.sleep(delay)
            return original_send(*args, **kwargs)
        self.producer.send = rate_limited_send
        
        # Upload using appropriate method
        if format_type == 'json':
            self.upload_from_jsonl(input_file, target_topic)
        elif format_type == 'binary':
            self.upload_from_binary(input_file, target_topic)


def main():
    parser = argparse.ArgumentParser(description='Upload messages back to Kafka with authentication')
    parser.add_argument('--brokers', default='kafka1:9092', help='Kafka bootstrap servers (comma-separated)')
    parser.add_argument('--input', required=True, help='Input file to upload')
    parser.add_argument('--topic', required=True, help='Target Kafka topic')
    parser.add_argument('--format', choices=['json', 'binary'], default='json', help='Input format')
    parser.add_argument('--preserve-timestamps', action='store_true', default=True,
                       help='Preserve original message timestamps (default: True)')
    parser.add_argument('--no-preserve-timestamps', action='store_false', dest='preserve_timestamps',
                       help='Use current timestamps instead of original')
    parser.add_argument('--rate-limit', type=int, help='Limit upload rate (messages per second)')
    parser.add_argument('--kafka-config', help='Kafka configuration file (JSON format)')
    
    args = parser.parse_args()
    
    # Show compression library status for supported file types
    if not HAS_ZSTD and (args.input.endswith('.zst')):
        print("Error: File has .zst extension but zstandard library not installed.")
        print("Install with: pip install zstandard")
        return 1
    
    # Load Kafka configuration
    kafka_config = None
    if args.kafka_config:
        try:
            kafka_config = load_kafka_config(args.kafka_config)
            print(f"Loaded Kafka configuration from {args.kafka_config}")
        except Exception as e:
            print(f"Error loading config: {e}")
            return 1
    
    # Create uploader and upload
    uploader = KafkaMessageUploader(args.brokers, args.preserve_timestamps, kafka_config)
    
    try:
        if args.rate_limit:
            uploader.batch_upload_with_rate_limit(args.input, args.topic, args.rate_limit, args.format)
        else:
            if args.format == 'json':
                uploader.upload_from_jsonl(args.input, args.topic)
            elif args.format == 'binary':
                uploader.upload_from_binary(args.input, args.topic)
    except KeyboardInterrupt:
        print("\nUpload interrupted by user")
    except Exception as e:
        print(f"Upload failed: {e}")
        return 1


if __name__ == "__main__":
    main()
