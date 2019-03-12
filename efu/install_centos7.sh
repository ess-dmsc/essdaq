#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

. ../config/scripts/numcpus.sh
. ../config/scripts/sshconfig.sh

sudo yum install -y cmake3 libpcap-devel ethtool glogg hdf5

if [[ $usessh =~ ^(yes|y| ) ]]; then
  git clone git@github.com:ess-dmsc/event-formation-unit.git
else
  git clone https://github.com/ess-dmsc/event-formation-unit.git
fi

mkdir -p $HOME/data
mkdir -p $HOME/data/efu_dump
mkdir ./event-formation-unit/build

pushd event-formation-unit/build
  scl enable devtoolset-6 -- conan install --build=boost_filesystem --options boost_filesystem:shared=True --options boost_system:shared=True boost_filesystem/1.69.0@bincrafters/stable
  scl enable devtoolset-6 -- conan install --build=outdated ..

  scl enable devtoolset-6 -- cmake3 -DCONAN=MANUAL ..
  #(or -DCMAKE_BUILD_TYPE=Release -DBUILDSTR=speedtest ..)

  scl enable devtoolset-6 -- make -j$NUMCPUS && make unit_tests -j$NUMCPUS

  scl enable devtoolset-6 -- make runtest && make runefu
popd

