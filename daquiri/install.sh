#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

. ../config/numcpus.sh
. ../config/sshconfig.sh

sudo apt install -y cmake qt5-default
if [[ $usessh =~ ^(yes|y| ) ]]; then
  git clone git@github.com:ess-dmsc/daquiri.git
else
  git clone https://github.com/ess-dmsc/daquiri.git
fi
pushd daquiri
./utils/first_build.sh -j$NUMCPUS
popd
