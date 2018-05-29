#!/bin/bash

read -r -p "Install and setup conan? [Y/n]" getconan
getconan=${getconan,,} # tolower
if [[ $getconan =~ ^(yes|y| ) ]]; then
sudo apt install -y python-pip
sudo pip2 install conan
conan remote add conancommunity https://api.bintray.com/conan/conan-community/conan
conan remote add conan-transit https://api.bintray.com/conan/conan/conan-transit
conan remote add bincrafters https://api.bintray.com/conan/bincrafters/public-conan
conan remote add ess-dmsc https://api.bintray.com/conan/ess-dmsc/conan
conan profile new --detect default
#only ubuntu
conan profile update settings.compiler.libcxx=libstdc++11 default
fi

read -r -p "Install docker and start up grafana? [Y/n]" getgrafana
getgrafana=${getgrafana,,} # tolower
if [[ $getgrafana =~ ^(yes|y| ) ]]; then
sudo apt install -y curl
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"
#should actually be like this when support for bionic arrives:
#sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce
sudo docker swarm init
sudo docker stack deploy -c docker-metrics-env/docker-compose.yml metrics
fi

read -r -p "Install kafka? [Y/n]" getfkafka
getfkafka=${getfkafka,,} # tolower
if [[ $getfkafka =~ ^(yes|y| ) ]]; then
sudo apt install -y curl default-jre
curl -LO http://ftp.download-by.net/apache/kafka/1.1.0/kafka_2.11-1.1.0.tgz
gunzip ./kafka_2.11-1.1.0.tgz
tar xvf ./kafka_2.11-1.1.0.tar
fi

read -r -p "Get and build EFU? [Y/n]" getefu
getefu=${getefu,,} # tolower
if [[ $getefu =~ ^(yes|y| ) ]]; then
sudo apt install -y cmake libpcap-dev
# could be (libpcap-devel on CentOS)
git clone https://github.com/ess-dmsc/event-formation-unit.git
mkdir ./event-formation-unit/build
pushd event-formation-unit/build
cmake ..
#(or -DCMAKE_BUILD_TYPE=Release -DBUILDSTR=speedtest ..)
make -j2
popd
fi

read -r -p "Get and build Daquiri? [Y/n]" getdaquiri
getdaquiri=${getdaquiri,,} # tolower
if [[ $getdaquiri =~ ^(yes|y| ) ]]; then
sudo apt install -y cmake qt5-default
git clone https://github.com/ess-dmsc/daquiri.git
pushd daquiri
./utils/first_build.sh
fi
