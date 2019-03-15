#!/bin/bash

INSTALLMODE=${1:-manual}

mkdir -p /tmp/results
export LOGFILE=/tmp/results/install.log

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

function errexit()
{
  echo Error: $1
  echo $1 >> $LOGFILE
}

function install_conan() {
  #TODO: do we use python3 instead?
  sudo apt-get install -y python-pip
  sudo pip2 install conan || exixt 1

  conan remote add conancommunity https://api.bintray.com/conan/conan-community/conan || exit 1
  conan remote add conan-transit https://api.bintray.com/conan/conan/conan-transit || exit 1
  conan remote add bincrafters https://api.bintray.com/conan/bincrafters/public-conan || exit 1
  conan remote add ess-dmsc https://api.bintray.com/conan/ess-dmsc/conan || exit 1

  conan profile new --detect default || exit 1
  conan profile update settings.compiler.libcxx=libstdc++11 default || exit 1

  echo "Conan install finished" >> $LOGFILE
}

#
#
#

rm -rf $LOGFILE

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
  install_conan || errexit "conan install failed"
fi

read -r -p "Install docker and start up grafana? [Y/n]" getgrafana
getgrafana=${getgrafana,,} # tolower
if [[ $getgrafana =~ ^(yes|y| ) ]]; then
  grafana/install.sh || errexit "grafana install failed"
fi

read -r -p "Install kafka? [Y/n]" getfkafka
getfkafka=${getfkafka,,} # tolower
if [[ $getfkafka =~ ^(yes|y| ) ]]; then
  ./kafka/install.sh || errexit "kafka install failed"
fi

read -r -p "Get and build EFU? [Y/n]" getefu
getefu=${getefu,,} # tolower
if [[ $getefu =~ ^(yes|y| ) ]]; then
  ./efu/install.sh || errexit "efu install failed"
fi

read -r -p "Get and build Daquiri? [Y/n]" getdaquiri
getdaquiri=${getdaquiri,,} # tolower
if [[ $getdaquiri =~ ^(yes|y| ) ]]; then
  ./daquiri/install.sh || errexit "daquiri install failed"
fi
