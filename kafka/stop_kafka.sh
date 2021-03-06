#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

echo "stopping Kafka and Zookeeper"

pushd kafka/bin

echo "Stopping Kafka"
./kafka-server-stop.sh

echo "Wait 10s for termination"
sleep 10

echo "Stopping Zookeeper"
./zookeeper-server-stop.sh
