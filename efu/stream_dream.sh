#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

#get config variables
. ../config/system.sh

UDPARG=""
if [[ $EFU_UDP != "" ]]; then
  UDPARG="-p $EFU_UDP"
fi

pushd event-formation-unit/build
. ./activate_run.sh
./bin/udpgen_jalousie $UDPARG -i $EFU_IP -f $@
popd

popd