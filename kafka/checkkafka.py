import argparse
import sys
import kafka


if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser(
        description="Check if Kafka cluster is available"
    )
    arg_parser.add_argument('bootstrap_servers')
    args = arg_parser.parse_args()

    try:
        c = kafka.KafkaConsumer(bootstrap_servers=args.bootstrap_servers)
    except kafka.errors.NoBrokersAvailable:
        print("Error: no brokers available")
        sys.exit(1)

    print("Brokers found")
    sys.exit(0)
