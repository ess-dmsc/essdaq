#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

. ../config/numcpus.sh

pushd event-formation-unit/build
git pull
cmake ..
#(or -DCMAKE_BUILD_TYPE=Release -DBUILDSTR=speedtest ..)
make -j$NUMCPUS && make unit_tests -j$NUMCPUS
make runtest && make runefu
popd
