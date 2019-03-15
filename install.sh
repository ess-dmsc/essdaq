#!/bin/bash

INSTALLMODE=${1:-manual}

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

function errexit()
{
  echo Error: $1
  exit 1
}

function install_conan() {
  #TODO: do we use python3 instead?
  sudo apt-get install -y --no-install-recommends python-pip
  sudo pip2 install conan
  conan remote add conancommunity https://api.bintray.com/conan/conan-community/conan
  conan remote add conan-transit https://api.bintray.com/conan/conan/conan-transit
  conan remote add bincrafters https://api.bintray.com/conan/bincrafters/public-conan
  conan remote add ess-dmsc https://api.bintray.com/conan/ess-dmsc/conan
  conan profile new --detect default
  #TODO: only ubuntu
  conan profile update settings.compiler.libcxx=libstdc++11 default

  echo "Conan install finished" >> ~/install.log
}

#
#
#

rm -rf ~/install.log

if [[ $INSTALLMODE == "auto" ]]; then
  echo "AUTOMATIC INSTALL"
  install_conan  || errexit "conan install failed"
  grafana/install.sh || errexit "grafana install failed"
  kafka/install.sh || errexit "kafka install failed"
  efu/install.sh || errexit "efu install failed"
  daquiri/install.sh || errexit "daquiri install failed"
  exit 0
fi

echo "INTERACTIVE INSTALL"
read -r -p "Install and setup conan? [Y/n]" getconan
getconan=${getconan,,} # tolower
if [[ $getconan =~ ^(yes|y| ) ]]; then
  install_conan
fi

read -r -p "Install docker and start up grafana? [Y/n]" getgrafana
getgrafana=${getgrafana,,} # tolower
if [[ $getgrafana =~ ^(yes|y| ) ]]; then
  grafana/install.sh
fi

read -r -p "Install kafka? [Y/n]" getfkafka
getfkafka=${getfkafka,,} # tolower
if [[ $getfkafka =~ ^(yes|y| ) ]]; then
  ./kafka/install.sh
fi

read -r -p "Get and build EFU? [Y/n]" getefu
getefu=${getefu,,} # tolower
if [[ $getefu =~ ^(yes|y| ) ]]; then
  ./efu/install.sh
fi

read -r -p "Get and build Daquiri? [Y/n]" getdaquiri
getdaquiri=${getdaquiri,,} # tolower
if [[ $getdaquiri =~ ^(yes|y| ) ]]; then
  ./daquiri/install.sh
fi
