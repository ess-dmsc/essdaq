#!/bin/bash

sudo apt install curl cmake default-jre qt5-default

# could be (libpcap-devel on CentOS)
sudo apt install libpcap-dev

#pip2 install conan
#conan remote add conancommunity https://api.bintray.com/conan/conan-community/conan
#conan remote add conan-transit https://api.bintray.com/conan/conan/conan-transit
#conan remote add bincrafters https://api.bintray.com/conan/bincrafters/public-conan
#conan remote add ess-dmsc https://api.bintray.com/conan/ess-dmsc/conan
#conan profile new --detect default

#exit 1

#edit ~/.conan/profiles/default to replace compiler.libcxx=libstdc++ with compiler.libcxx=libstdc++11

#docker.io - FOLLOW INSTRUCTIONS FROM https://store.docker.com/search?type=edition&offering=community

#git clone https://github.com/ess-dmsc/utils.git
#cd utils
sudo docker swarm init
sudo docker stack deploy -c docker-metrics-env/docker-compose.yml metrics 

curl -LO http://ftp.download-by.net/apache/kafka/1.0.0/kafka_2.11-1.0.0.tgz
gunzip ./kafka_2.11-1.0.0.tgz
tar xvf ./kafka_2.11-1.0.0.tar

git clone https://github.com/ess-dmsc/event-formation-unit.git
cd event-formation-unit
mkdir build
cd build
cmake ..
#(or -DCMAKE_BUILD_TYPE=Release -DBUILDSTR=speedtest ..)
make

cd ../..

git clone https://github.com/ess-dmsc/daquiri.git
#cd daquiri
#./utils/first_build.sh

#./bin/efu -d lib/gdgem -f ../prototype2/gdgem/nmx_config.json -p 6006 -c -5



