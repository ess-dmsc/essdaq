#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

#get config variables
. ../config_variables.sh

sudo apt install -y cmake libpcap-dev ethtool glogg
#TODO: could be libpcap-devel on CentOS
if [[ $usessh =~ ^(yes|y| ) ]]; then
  git clone git@github.com:ess-dmsc/event-formation-unit.git
else
  git clone https://github.com/ess-dmsc/event-formation-unit.git
fi
mkdir ./event-formation-unit/build
pushd event-formation-unit/build
cmake ..
#(or -DCMAKE_BUILD_TYPE=Release -DBUILDSTR=speedtest ..)
make -j$NUMCPUS && make unit_tests -j$NUMCPUS
make runtest && make runefu
popd

