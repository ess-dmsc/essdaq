#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

. version.sh

read -r -p "Before we proceed, it is rocommended that you update your system's packages. Shall we do this? [Y/n]" aptupdate
aptupdate=${aptupdate,,} # tolower
if [[ $aptupdate =~ ^(yes|y| ) ]]; then
  sudo apt update
fi

kafkafile="kafka_2.11-$kafkaversion"
sudo apt install -y curl default-jre
curl -LO http://ftp.download-by.net/apache/kafka/$kafkaversion/$kafkafile.tgz
#TODO: ensure download is successful
gunzip ./$kafkafile.tgz
tar xvf ./$kafkafile.tar
rm -f ./$kafkafile.tar

#patch the script for most recent java version
mv ./$kafkafile/bin/kafka-run-class.sh ./$kafkafile/bin/old_kafka-run-class.sh
sed -e 's/\/\\1\/p/\.\*\/\\1\/p/' ./$kafkafile/bin/old_kafka-run-class.sh > ./$kafkafile/bin/kafka-run-class.sh
chmod +x ./$kafkafile/bin/kafka-run-class.sh
