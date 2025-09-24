#!/usr/bin/env python3
"""
Kafka Message Uploader - Compact Version
Uploads previously downloaded Kafka messages with SASL/SSL support.
Preserves timestamps by default and handles binary FlatBuffers data.
"""

from kafka import KafkaProducer
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
        
        # Base producer config
        config = {
            'bootstrap_servers': brokers if isinstance(brokers, list) else brokers.split(','),
            'acks': 'all',
            'retries': 3,
            'batch_size': 16384,
            'linger_ms': 10,
            'buffer_memory': 33554432,
            'key_serializer': lambda x: x if isinstance(x, bytes) else x.encode('utf-8') if isinstance(x, str) else None,
            'value_serializer': lambda x: x if isinstance(x, bytes) else x.encode('utf-8') if isinstance(x, str) else None
        }
        
        # Apply Kafka config (producer-specific mappings)
        if kafka_config:
            mappings = {
                'message.max.bytes': 'max_request_size',
                'message.timeout.ms': 'request_timeout_ms',
                'queue.buffering.max.ms': 'linger_ms',
                'batch.size': 'batch_size',
                'retries': 'retries',
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
            
            # Skip consumer-only configs
            skip = {'fetch.message.max.bytes', 'statistics.interval.ms', 'api.version.request', 'message.copy.max.bytes'}
            
            for key, value in kafka_config.items():
                if key not in skip and key in mappings:
                    config[mappings[key]] = value
        
        # Ensure proper timeout relationships
        linger_ms = config.get('linger_ms', 0)
        request_timeout_ms = config.get('request_timeout_ms', 30000)
        min_delivery_timeout = linger_ms + request_timeout_ms + 1000
        if config.get('delivery_timeout_ms', 0) <= min_delivery_timeout:
            config['delivery_timeout_ms'] = min_delivery_timeout
        
        self.producer = KafkaProducer(**config)
    
    def upload_from_jsonl(self, jsonl_file, target_topic):
        """Upload messages from JSON Lines format"""
        count = errors = 0
        
        # Use the new decompressor function
        decompressor, decomp_info = get_decompressor(jsonl_file)
        print(f"Using {decomp_info}")
        
        with decompressor as f:
            # For text mode, wrap binary streams
            if hasattr(f, 'mode') and 'b' in str(f.mode):
                import io
                f = io.TextIOWrapper(f, encoding='utf-8')
            
            for line_num, line in enumerate(f, 1):
                try:
                    record = json.loads(line.strip())
                    
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
                    timestamp_ms = record.get('timestamp') if self.preserve_timestamps else None
                    
                    # Send message
                    self.producer.send(
                        target_topic,
                        key=key,
                        value=value,
                        partition=record.get('partition'),
                        timestamp_ms=timestamp_ms
                    )
                    
                    count += 1
                    if count % 1000 == 0:
                        print(f"Uploaded {count} messages...")
                        self.producer.flush()
                        
                except Exception as e:
                    print(f"Error on line {line_num}: {e}")
                    errors += 1
        
        # Final flush and status
        self.producer.flush()
        print(f"Upload completed: {count} messages sent, {errors} errors")
    
    def upload_from_binary(self, binary_file, target_topic):
        """Upload messages from binary pickle format"""
        count = errors = 0
        
        # Use the new decompressor function
        decompressor, decomp_info = get_decompressor(binary_file)
        print(f"Using {decomp_info}")
        
        with decompressor as f:
            while True:
                try:
                    record = pickle.load(f)
                    
                    # Prepare data
                    key = record['key'].decode('utf-8', errors='ignore') if record['key'] else None
                    value = record['value']
                    timestamp_ms = record.get('timestamp') if self.preserve_timestamps else None
                    
                    # Send message
                    self.producer.send(
                        target_topic,
                        key=key,
                        value=value,
                        timestamp_ms=timestamp_ms
                    )
                    
                    count += 1
                    if count % 1000 == 0:
                        print(f"Uploaded {count} messages...")
                        self.producer.flush()
                        
                except EOFError:
                    break
                except Exception as e:
                    print(f"Error processing message: {e}")
                    errors += 1
        
        self.producer.flush()
        print(f"Upload completed: {count} messages sent, {errors} errors")
    
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
