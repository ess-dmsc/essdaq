#!/bin/bash

HAVETOOLSET=$(set | grep devtoolset\-6)

if [[ $HAVETOOLSET == "" ]]; then
  echo Error: devtoolset-6 not activated, but is required.
  echo Before calling scripts, first execute the following command
  echo '> scl enable devtoolset-6 -- ./install_centos7.sh'
  exit 0
fi

INSTALLMODE=${1:-manual}

mkdir -p /tmp/results
export LOGFILE=/tmp/results/install.log

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

function errexit()
{
  echo Error: $1
  exit 1
}

function install_conan() {
  #TODO: do we use python3 instead? (issues on CentOS7 w/ 3.4 and 3.6!)
  sudo yum install -y python-pip
  sudo pip2 install --upgrade pip # installs pip > 19.0.3
  #sudo pip3.6 install --upgrade pip # kills itself..?!
  #sudo pip3.4 install --upgrade pip # installs pip > 19.0.3; python3.4 not maintained after March 2019; conan NOT working
  sudo pip2 install conan || exit 1
  conan remote add bincrafters https://api.bintray.com/conan/bincrafters/public-conan || exit 1
  conan remote add conancommunity https://api.bintray.com/conan/conan-community/conan || exit 1
  conan remote add conan-transit https://api.bintray.com/conan/conan/conan-transit || exit 1
  conan remote add ess-dmsc https://api.bintray.com/conan/ess-dmsc/conan || exit 1
  conan profile new --detect default || exit 1

  echo "Conan install finished" >> $LOGFILE
}

#
#
#

rm -rf $LOGFILE

if [[ $INSTALLMODE == "auto" ]]; then
  echo "AUTOMATIC INSTALL"
  install_conan || errexit "conan install failed"
  grafana/install_centos7.sh || errexit "grafana install failed"
  kafka/install_centos7.sh || errexit "kafka install failed"
  efu/install_centos7.sh || errexit "efu install failed"
  echo NOT INSTALLING DAQUIRI YET
  #daquiri/install_centos7.sh || errexit "daquiri install failed"
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
  grafana/install_centos7.sh || errexit "grafana install failed"
fi

read -r -p "Install kafka? [Y/n]" getfkafka
getfkafka=${getfkafka,,} # tolower
if [[ $getfkafka =~ ^(yes|y| ) ]]; then
  ./kafka/install_centos7.sh || errexit "kafka install failed"
fi

read -r -p "Get and build EFU? [Y/n]" getefu
getefu=${getefu,,} # tolower
if [[ $getefu =~ ^(yes|y| ) ]]; then
  ./efu/install_centos7.sh || errexit "efu install failed"
fi

read -r -p "Get and build Daquiri? [Y/n]" getdaquiri
getdaquiri=${getdaquiri,,} # tolower
if [[ $getdaquiri =~ ^(yes|y| ) ]]; then
  ./daquiri/install_centos7.sh || errexit "daquiri install failed"
fi
