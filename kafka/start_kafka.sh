#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

. version.sh

echo "Starting Zookeeper and Kafka"
echo "Kafka version $kafkaversion"

pushd kafka_2.11-$kafkaversion

echo "Starting Zookeeper"
./bin/zookeeper-server-start.sh -daemon ./config/zookeeper.properties

echo "Starting Kafka"
./bin/kafka-server-start.sh -daemon ../server.config

