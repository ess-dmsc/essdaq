#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

. ../config/numcpus.sh

pushd daquiri
 /utils/update_build.sh -j$NUMCPUS
popd
