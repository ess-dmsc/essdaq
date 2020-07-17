#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

echo "stopping Kafka and Zookeeper"

pushd kafka/bin

echo "Stopping Kafka"
./kafka-server-stop.sh

echo "Stopping Zookeeper"
./zookeeper-server-stop.sh
