#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

. ../config/scripts/numcpus.sh
. ../config/scripts/sshconfig.sh

#sudo add-apt-repository ppa:wireshark-dev/stable
sudo apt update
sudo apt-get install -y vim cmake flex ethtool glogg hdf5-tools wireshark

if [[ $usessh =~ ^(yes|y| ) ]]; then
  git clone git@github.com:ess-dmsc/event-formation-unit.git
else
  git clone https://github.com/ess-dmsc/event-formation-unit.git
fi

mkdir -p $HOME/data/efu_dump
mkdir ./event-formation-unit/build
pushd event-formation-unit/build
  cmake ..
  #(or -DCMAKE_BUILD_TYPE=Release -DBUILDSTR=speedtest ..)
  make -j$NUMCPUS && make unit_tests -j$NUMCPUS
  make runtest && make runefu
popd

echo "EFU install finished" >> $LOGFILE
