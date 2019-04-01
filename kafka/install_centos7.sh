#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

. version.sh

echo "Kafka install started: "$(date) | tee -a $LOGFILE

kafkafile="kafka_2.11-$kafkaversion"
sudo yum install -y python34-pip curl java-1.7.0-openjdk
sudo pip3.4 install kafka-python
sudo pip3.4 install argparse
echo "Downloading version: $kafkaversion, file: $kafkafile.tgz"
curl -LO http://ftp.download-by.net/apache/kafka/$kafkaversion/$kafkafile.tgz
#TODO: ensure download is successful

tar xvzf ./$kafkafile.tgz || exit 1
rm -f ./$kafkafile.tar || exit 1


#for older (pre- 2.0) kafka versions
#patch the script for most recent java version
#mv ./$kafkafile/bin/kafka-run-class.sh ./$kafkafile/bin/old_kafka-run-class.sh
#sed -e 's/\/\\1\/p/\.\*\/\\1\/p/' ./$kafkafile/bin/old_kafka-run-class.sh > ./$kafkafile/bin/kafka-run-class.sh
#chmod +x ./$kafkafile/bin/kafka-run-class.sh

./start_kafka.sh || exit 1
./verify_install.sh || exit 1

echo "Kafka install finished" | tee -a $LOGFILE
