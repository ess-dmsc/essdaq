#!/bin/bash

INSTALLMODE=${1:-manual}

mkdir -p /tmp/results
export LOGFILE=/tmp/results/install.log

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

function errlog()
{
  echo Error: $1
  echo Error: $1 >> $LOGFILE
}

function install_conan() {
  #TODO: do we use python3 instead?
  sudo apt-get install -y python-pip
  sudo pip3 install conan || sudo pip2 install conan || exit 1

  conan config install https://github.com/ess-dmsc/conan-configuration.git || exit 1

  conan profile new --detect default || exit 1
  conan profile update settings.compiler.libcxx=libstdc++11 default || exit 1

  echo "Conan install finished" >> $LOGFILE
}

#
#
#

echo "Starting install: "$(date) > $LOGFILE

if [[ $INSTALLMODE == "auto" ]]; then
  echo "AUTOMATIC INSTALL"
  install_conan  || errlog "conan install failed"
  grafana/install.sh || errlog "grafana install failed"
  kafka/install.sh || errlog "kafka install failed"
  efu/install.sh || errlog "efu install failed"
  daquiri/install.sh || errlog "daquiri install failed"
  echo "Install finished: "$(date) >> $LOGFILE
  cat $LOGFILE
  exit 0
fi

echo "INTERACTIVE INSTALL"
read -r -p "Install and setup conan? [Y/n]" getconan
getconan=${getconan,,} # tolower
if [[ $getconan =~ ^(yes|y| ) ]]; then
  install_conan || errlog "conan install failed"
fi

read -r -p "Install docker and start up grafana? [Y/n]" getgrafana
getgrafana=${getgrafana,,} # tolower
if [[ $getgrafana =~ ^(yes|y| ) ]]; then
  grafana/install.sh || errlog "grafana install failed"
fi

read -r -p "Install kafka? [Y/n]" getfkafka
getfkafka=${getfkafka,,} # tolower
if [[ $getfkafka =~ ^(yes|y| ) ]]; then
  ./kafka/install.sh || errlog "kafka install failed"
fi

read -r -p "Get and build EFU? [Y/n]" getefu
getefu=${getefu,,} # tolower
if [[ $getefu =~ ^(yes|y| ) ]]; then
  ./efu/install.sh || errlog "efu install failed"
fi

read -r -p "Get and build Daquiri? [Y/n]" getdaquiri
getdaquiri=${getdaquiri,,} # tolower
if [[ $getdaquiri =~ ^(yes|y| ) ]]; then
  ./daquiri/install.sh || errlog "daquiri install failed"
fi

echo "Install finished: "$(date) >> $LOGFILE
cat $LOGFILE
