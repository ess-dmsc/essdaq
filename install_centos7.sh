#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

read -r -p "Install and setup conan? [Y/n]" getconan
getconan=${getconan,,} # tolower
if [[ $getconan =~ ^(yes|y| ) ]]; then
  #TODO: do we use python3 instead? (issues on CentOS7 w/ 3.4 and 3.6!)
  sudo yum install -y python-pip
  sudo pip2 install --upgrade pip # installs pip > 19.0.3
  #sudo pip3.6 install --upgrade pip # kills itself..?!
  #sudo pip3.4 install --upgrade pip # installs pip > 19.0.3; python3.4 not maintained after March 2019; conan NOT working
  sudo pip2 install conan
  conan remote add conancommunity https://api.bintray.com/conan/conan-community/conan
  conan remote add conan-transit https://api.bintray.com/conan/conan/conan-transit
  conan remote add bincrafters https://api.bintray.com/conan/bincrafters/public-conan
  conan remote add ess-dmsc https://api.bintray.com/conan/ess-dmsc/conan
  scl enable devtoolset-7 -- conan profile new --detect default
  #TODO: only Linux-machines w/ native gcc>=5 (forces new ABI); DO NOT USE ON CENTOS7
  #conan profile update settings.compiler.libcxx=libstdc++11 default
fi

read -r -p "Install docker and start up grafana? [Y/n]" getgrafana
getgrafana=${getgrafana,,} # tolower
if [[ $getgrafana =~ ^(yes|y| ) ]]; then
  grafana/install_centos7.sh
fi

read -r -p "Install kafka? [Y/n]" getfkafka
getfkafka=${getfkafka,,} # tolower
if [[ $getfkafka =~ ^(yes|y| ) ]]; then
  ./kafka/install_centos7.sh
fi

read -r -p "Get and build EFU? [Y/n]" getefu
getefu=${getefu,,} # tolower
if [[ $getefu =~ ^(yes|y| ) ]]; then
  ./efu/install_centos7.sh
fi

read -r -p "Get and build Daquiri? [Y/n]" getdaquiri
getdaquiri=${getdaquiri,,} # tolower
if [[ $getdaquiri =~ ^(yes|y| ) ]]; then
  ./daquiri/install.sh
fi
