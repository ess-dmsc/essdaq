#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../config/system.sh

UDPARG=""
if [[ $EFU_UDP != "" ]]; then
  UDPARG="-p $EFU_UDP"
fi

pushd ./event-formation-unit/build
./bin/efu --read_config $HOME/essdaq/detectors/$DETECTOR/config.ini $UDPARG -b $KAFKA_IP -g $GRAFANA_IP $@ &>> $THISDIR/logfile.txt &
popd

popd
