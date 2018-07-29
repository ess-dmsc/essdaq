#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../config_variables.sh

pushd ../event-formation-unit/build
./bin/udpgen_pcap -i $EFU_IP -t 100 -f $@


