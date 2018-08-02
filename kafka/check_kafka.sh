#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

#get config variables
. ../config_variables.sh

echo "Checking Kafka"

python3 check_kafka.py $KAFKA_IP
