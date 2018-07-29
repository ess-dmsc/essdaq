#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

#get config variables
. ../config_variables.sh

pushd event-formation-unit/build
./bin/udpgen_pcap -i $EFU_IP -t 100 -f $@
popd
