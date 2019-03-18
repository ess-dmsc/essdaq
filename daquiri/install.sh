#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

. ../config/scripts/numcpus.sh
. ../config/scripts/sshconfig.sh

sudo apt-get install -y cmake qt5-default || exit 1
if [[ $usessh =~ ^(yes|y| ) ]]; then
  git clone git@github.com:ess-dmsc/daquiri.git || exit 1
else
  git clone https://github.com/ess-dmsc/daquiri.git || exit 1
fi

pushd daquiri
  ./utils/first_build.sh -j$NUMCPUS || exit 1
popd

echo "Daquiri install finished" >> $LOGFILE
