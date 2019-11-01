#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

. version.sh

echo "Kafka install started: "$(date) | tee -a $LOGFILE

kafkafile="kafka_2.11-$kafkaversion"
sudo apt update && sudo apt-get install -y curl default-jre python3-pip
sudo pip3 install kafka-python
sudo pip3 install argparse
curl -LO http://ftp.download-by.net/apache/kafka/$kafkaversion/$kafkafile.tgz
#TODO: ensure download is successful

tar xvzf ./$kafkafile.tgz || exit 1
rm -f ./$kafkafile.tar

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
sed -e "s/^listeners=.*/listeners=PLAINTEXT:\/\/$IP:9092/g" -i .bak server.config

./start_kafka.sh || exit 1
./verify_install.sh || exit 1

echo "Kafka install finished: "$(date) | tee -a $LOGFILE
echo "Check IP address for listeners (use setlisteners.sh to change)" | tee -a $LOGFILE
