#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

echo "Daquiri install started: "$(date) | tee -a $LOGFILE

. ../config/scripts/numcpus.sh
. ../config/scripts/sshconfig.sh

sudo yum install -y cmake3 qt5-qtbase-devel
if [[ $usessh =~ ^(yes|y| ) ]]; then
  git clone git@github.com:ess-dmsc/daquiri.git || exit 1
else
  git clone https://github.com/ess-dmsc/daquiri.git || exit 1
fi

pushd daquiri
  sed -i 's/cmake/cmake3/' ./utils/first_build.sh
  ./utils/first_build.sh -j$NUMCPUS || exit 1
popd

echo "Daquiri install finished: "$(date) | tee -a $LOGFILE
