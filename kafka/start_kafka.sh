#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

echo "Starting Zookeeper and Kafka"
echo "Kafka version $kafkaversion"

pushd kafka

echo "Starting Zookeeper"
./bin/zookeeper-server-start.sh -daemon ./config/zookeeper.properties

echo "Starting Kafka"
./bin/kafka-server-start.sh -daemon ../server.config

popd

