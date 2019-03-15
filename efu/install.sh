#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

. ../config/scripts/numcpus.sh
. ../config/scripts/sshconfig.sh

#sudo add-apt-repository ppa:wireshark-dev/stable
sudo apt update
sudo apt-get install -y vim cmake flex ethtool glogg hdf5-tools
#sudo apt-get install -y wireshark

if [[ $usessh =~ ^(yes|y| ) ]]; then
  git clone git@github.com:ess-dmsc/event-formation-unit.git || exit 1
else
  git clone https://github.com/ess-dmsc/event-formation-unit.git || exit 1
fi

mkdir -p $HOME/data/efu_dump
mkdir ./event-formation-unit/build
pushd event-formation-unit/build
  conan install --build=outdated .. || exit 1
  cmake -DCONAN=MANUAL .. || exit 1

  make -j$NUMCPUS || exit 1
  make unit_tests -j$NUMCPUS || exit 1
  make runtest  || exit 1
  make runefu || exit 1
popd

echo "EFU install finished" >> $LOGFILE
