#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

echo "Kafka install started: "$(date) | tee -a $LOGFILE

sudo apt update && sudo apt-get install -y curl default-jre python3-pip
sudo pip3 install kafka-python
sudo pip3 install argparse

kafka=kafka_2.13-2.5.0
kafkafile=$kafka.tgz
kafkaurl=http://ftp.download-by.net/apache/kafka/2.5.0/
curl -LO $kafkaurl/$kafkafile
#TODO: ensure download is successful

tar xvzf ./$kafkafile|| exit 1
rm -f ./$kafkafile
ln -s $kafka kafka

#for older (pre- 2.0) kafka versions
#patch the script for most recent java version
#mv ./$kafkafile/bin/kafka-run-class.sh ./$kafkafile/bin/old_kafka-run-class.sh
#sed -e 's/\/\\1\/p/\.\*\/\\1\/p/' ./$kafkafile/bin/old_kafka-run-class.sh > ./$kafkafile/bin/kafka-run-class.sh
#chmod +x ./$kafkafile/bin/kafka-run-class.sh

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
sed -e "s/^advertised.listeners=.*/advertised.listeners=PLAINTEXT:\/\/$IP:9092/g" -i .bak server.config

./start_kafka.sh || exit 1
./verify_install.sh || exit 1

echo "Kafka install finished: "$(date) | tee -a $LOGFILE
echo "Check IP address for listeners (use setlisteners.sh to change)" | tee -a $LOGFILE
