#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

# build with 1 less than total number of CPUS, minimum 1
NUMCPUS=$(cat /proc/cpuinfo | grep -c processor)
let NUMCPUS-=1
if [ "$NUMCPUS" -lt "1" ]; then
  NUMCPUS=1
fi

read -r -p "Before we proceed, it is rocommended that you update your system's packages. Shall we do this? [Y/n]" aptupdate
aptupdate=${aptupdate,,} # tolower
if [[ $aptupdate =~ ^(yes|y| ) ]]; then
  sudo apt update
fi

read -r -p "Update conan? [Y/n]" getconan
getconan=${getconan,,} # tolower
if [[ $getconan =~ ^(yes|y| ) ]]; then
  #TODO: do we use python3 instead?
  sudo pip2 install -u conan
  conan --version
fi

read -r -p "Update EFU? [Y/n]" getefu
getefu=${getefu,,} # tolower
if [[ $getefu =~ ^(yes|y| ) ]]; then
  pushd event-formation-unit/build
  git pull
  cmake ..
  #(or -DCMAKE_BUILD_TYPE=Release -DBUILDSTR=speedtest ..)
  make -j$NUMCPUS && make unit_tests -j$NUMCPUS
  make runtest && make runefu
  popd
fi

read -r -p "Update Daquiri? [Y/n]" getdaquiri
getdaquiri=${getdaquiri,,} # tolower
if [[ $getdaquiri =~ ^(yes|y| ) ]]; then
  pushd daquiri
  ./utils/update_build.sh -j$NUMCPUS
  popd
fi
