#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

#get config variables
. ../config/system.sh

pushd event-formation-unit/build
./bin/udpgen_pcap -i $EFU_IP -t 5000 -f $@
popd
