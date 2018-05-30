#!/bin/bash

kafkaversion="1.1.0"

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

# build with 1 less than total number of CPUS, minimum 1
NUMCPUS=$(cat /proc/cpuinfo | grep -c processor)
let NUMCPUS-=1
if [ "$NUMCPUS" -lt "1" ]; then
  NUMCPUS=1
fi

read -r -p "Before we proceed, it is rocommended that you update your system's packages. Shall we do this? [Y/n]" aptupdate
aptupdate=${aptupdate,,} # tolower
if [[ $aptupdate =~ ^(yes|y| ) ]]; then
  sudo apt update
fi

#TODO: should determine this automatically?
read -r -p "Use ssh instead of http for cloning repos? [Y/n]" usessh
usessh=${usessh,,} # tolower


read -r -p "Install and setup conan? [Y/n]" getconan
getconan=${getconan,,} # tolower
if [[ $getconan =~ ^(yes|y| ) ]]; then
  #TODO: do we use python3 instead?
  sudo apt install -y python-pip
  sudo pip2 install conan
  conan remote add conancommunity https://api.bintray.com/conan/conan-community/conan
  conan remote add conan-transit https://api.bintray.com/conan/conan/conan-transit
  conan remote add bincrafters https://api.bintray.com/conan/bincrafters/public-conan
  conan remote add ess-dmsc https://api.bintray.com/conan/ess-dmsc/conan
  conan profile new --detect default
  #TODO: only ubuntu
  conan profile update settings.compiler.libcxx=libstdc++11 default
fi

read -r -p "Install docker and start up grafana? [Y/n]" getgrafana
getgrafana=${getgrafana,,} # tolower
if [[ $getgrafana =~ ^(yes|y| ) ]]; then
  sudo apt install -y curl
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"
  #TODO: should actually be like this when support for bionic arrives:
  #sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get update
  sudo apt-get install -y docker-ce
  sudo docker swarm init
  sudo docker stack deploy -c docker-metrics-env/docker-compose.yml metrics
fi

read -r -p "Install kafka? [Y/n]" getfkafka
getfkafka=${getfkafka,,} # tolower
if [[ $getfkafka =~ ^(yes|y| ) ]]; then
  kafkafile="kafka_2.11-$kafkaversion"
  sudo apt install -y curl default-jre
  curl -LO http://ftp.download-by.net/apache/kafka/$kafkaversion/$kafkafile.tgz
  #TODO: ensure download is successful
  gunzip ./$kafkafile.tgz
  tar xvf ./$kafkafile.tar
  rm -f ./$kafkafile.tar

  #patch the script for most recent java version
  replace_with="JAVA_MAJOR_VERSION=\$(\$JAVA -version 2>&1 | sed -E -n 's/.* version \"([^.-]*).*\".*/\1/p')"
  #awk_line='NR==4 {$0="$replace_with"} 1'
  #awk 'NR==4 {$0="$replace_with"} 1' ./$kafkafile/bin/kafka-run-class.sh
fi

read -r -p "Get and build EFU? [Y/n]" getefu
getefu=${getefu,,} # tolower
if [[ $getefu =~ ^(yes|y| ) ]]; then
  sudo apt install -y cmake libpcap-dev
  #TODO: could be libpcap-devel on CentOS
  if [[ $usessh =~ ^(yes|y| ) ]]; then
    git clone git@github.com:ess-dmsc/event-formation-unit.git
  else
    git clone https://github.com/ess-dmsc/event-formation-unit.git
  fi
  mkdir ./event-formation-unit/build
  pushd event-formation-unit/build
  cmake ..
  #(or -DCMAKE_BUILD_TYPE=Release -DBUILDSTR=speedtest ..)
  make -j$NUMCPUS && make unit_tests -j$NUMCPUS
  make runtest && make runefu
  popd
fi

read -r -p "Get and build Daquiri? [Y/n]" getdaquiri
getdaquiri=${getdaquiri,,} # tolower
if [[ $getdaquiri =~ ^(yes|y| ) ]]; then
  sudo apt install -y cmake qt5-default
  if [[ $usessh =~ ^(yes|y| ) ]]; then
    git clone git@github.com:ess-dmsc/daquiri.git
  else
    git clone https://github.com/ess-dmsc/daquiri.git
  fi
  pushd daquiri
  ./utils/first_build.sh -j$NUMCPUS
  popd
fi
