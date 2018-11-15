#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

#get config variables
. ../config/system.sh

echo "Checking Kafka at ip address $KAFKA_IP"

python3 check_kafka.py $KAFKA_IP

echo checking for local kafka instance
netstat -an | grep tcp |  grep 9092 | grep LISTEN &>/dev/null 
if [[ $? == "0" ]]; then
    echo "Kafka running locally"
else
    echo "No local Kafka found"
fi
