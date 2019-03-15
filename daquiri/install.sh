#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

. ../config/scripts/numcpus.sh
. ../config/scripts/sshconfig.sh

sudo apt-get install -y cmake qt5-default
if [[ $usessh =~ ^(yes|y| ) ]]; then
  git clone git@github.com:ess-dmsc/daquiri.git
else
  git clone https://github.com/ess-dmsc/daquiri.git
fi
pushd daquiri
  ./utils/first_build.sh -j$NUMCPUS
popd

echo "Daquiri install finished" >> $LOGFILE
