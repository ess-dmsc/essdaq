#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

. ../config/scripts/numcpus.sh
. ../config/scripts/sshconfig.sh

sudo yum install -y cmake3 libpcap-devel ethtool glogg hdf5

if [[ $usessh =~ ^(yes|y| ) ]]; then
  git clone git@github.com:ess-dmsc/event-formation-unit.git || exit 1
else
  git clone https://github.com/ess-dmsc/event-formation-unit.git || exit 1
fi

mkdir -p $HOME/data/efu_dump
mkdir ./event-formation-unit/build

pushd event-formation-unit/build
  scl enable devtoolset-6 -- conan install --build=boost_filesystem --options boost_filesystem:shared=True \
      --options boost_system:shared=True boost_filesystem/1.69.0@bincrafters/stable || exit 1
  scl enable devtoolset-6 -- conan install --build=outdated .. || exit 1

  scl enable devtoolset-6 -- cmake3 -DCONAN=MANUAL .. || exit 1
  #(or -DCMAKE_BUILD_TYPE=Release -DBUILDSTR=speedtest ..)

  scl enable devtoolset-6 -- make -j$NUMCPUS || exit 1
  scl enable devtoolset-6 -- make unit_tests -j$NUMCPUS || exit 1

  scl enable devtoolset-6 -- make runtest || exit 1
  scl enable devtoolset-6 -- make runefu || exit 1
popd

echo "EFU install finished" >> $LOGFILE
