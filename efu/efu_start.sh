#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../config_variables.sh

pushd ./event-formation-unit/build

./bin/efu --read_config $HOME/essdaq/detectors/$DETECTOR/config.ini $@ &>> $THISDIR/logfile &

popd
popd
