#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

. version.sh

kafkafile="kafka_2.11-$kafkaversion"
sudo apt update && sudo apt-get install -y curl default-jre python3-pip
sudo pip3 install kafka-python
sudo pip3 install argparse
curl -LO http://ftp.download-by.net/apache/kafka/$kafkaversion/$kafkafile.tgz
#TODO: ensure download is successful

gunzip ./$kafkafile.tgz || exit 1
tar xvf ./$kafkafile.tar || exit 1
rm -f ./$kafkafile.tar

#for older (pre- 2.0) kafka versions
#patch the script for most recent java version
#mv ./$kafkafile/bin/kafka-run-class.sh ./$kafkafile/bin/old_kafka-run-class.sh
#sed -e 's/\/\\1\/p/\.\*\/\\1\/p/' ./$kafkafile/bin/old_kafka-run-class.sh > ./$kafkafile/bin/kafka-run-class.sh
#chmod +x ./$kafkafile/bin/kafka-run-class.sh

./start_kafka.sh || exit 1
./verify_install.sh || exit 1

echo "Kafka install finished" >> $LOGFILE
