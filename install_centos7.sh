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

function errlog()
{
  echo Error: $1
  echo Error: $1 >> $LOGFILE
}

function install_conan() {
  echo "Conan install started: "$(date) | tee -a $LOGFILE

  sudo yum install -y python36 python36-pip || exit 1
  sudo python36 -m venv /opt/conan-venv || exit 1
  sudo /opt/conan-venv/bin/pip install --upgrade pip setuptools || exit 1
  sudo /opt/conan-venv/bin/pip install conan || exit 1
  sudo ln -s /opt/conan-venv/bin/conan /usr/local/bin/conan || exit 1

  conan config install http://github.com/ess-dmsc/conan-configuration.git || exit 1
  sed -i '/\[build_requires\]/a cmake_installer\/3.10.0@conan\/stable' ~/.conan/profiles/default

  conan profile new --detect default || exit 1

  echo "Conan install finished: "$(date) | tee -a $LOGFILE
}

#
#
#

echo "Starting install: "$(date) > $LOGFILE

if [[ $INSTALLMODE == "auto" ]]; then
  echo "AUTOMATIC INSTALL"
  #install_conan || errlog "conan install failed"
  grafana/install_centos7.sh || errlog "grafana install failed"
  #kafka/install_centos7.sh || errlog "kafka install failed"
  #efu/install_centos7.sh || errlog "efu install failed"
  #daquiri/install_centos7.sh || errlog "daquiri install failed"
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
  grafana/install_centos7.sh || errlog "grafana install failed"
fi

read -r -p "Install kafka? [Y/n]" getfkafka
getfkafka=${getfkafka,,} # tolower
if [[ $getfkafka =~ ^(yes|y| ) ]]; then
  ./kafka/install_centos7.sh || errlog "kafka install failed"
fi

read -r -p "Get and build EFU? [Y/n]" getefu
getefu=${getefu,,} # tolower
if [[ $getefu =~ ^(yes|y| ) ]]; then
  ./efu/install_centos7.sh || errlog "efu install failed"
fi

read -r -p "Get and build Daquiri? [Y/n]" getdaquiri
getdaquiri=${getdaquiri,,} # tolower
if [[ $getdaquiri =~ ^(yes|y| ) ]]; then
  ./daquiri/install_centos7.sh || errlog "daquiri install failed"
fi

echo "Install finished: "$(date) >> $LOGFILE
cat $LOGFILE
