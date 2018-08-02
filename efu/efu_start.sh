#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../config/system.sh

pushd ./event-formation-unit/build

./bin/efu --read_config $HOME/essdaq/detectors/$DETECTOR/config.ini -b $KAFKA_IP -g $GRAFANA_IP $@ &>> $THISDIR/logfile &

popd
popd
