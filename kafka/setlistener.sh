#!/bin/bash

# ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

if test -f "../config/system.sh"; then
  # get config variables
  . ../config/system.sh
  IP=$KAFKA_IP
fi

if [[ $IP == "" ]]; then
  echo "No KAFKA_IP, setting IP to 127.0.0.1 (change with setlistener.sh)" | tee -a $LOGFILE
  IP="127.0.0.1"
fi

echo "Kafka IP address: "$IP | tee -a $LOGFILE
sed -e "s/^listeners=.*/listeners=PLAINTEXT:\/\/$IP:9092/g" -i .bak server.config
