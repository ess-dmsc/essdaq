#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

#get config variables
. ../../config/system.sh

echo "RUNNING ADC SIMULATOR"

#ensure that we are in the script directory
pushd $THISDIR

pushd ../../efu/event-formation-unit/build &> /dev/null || errexit "directory ./event-formation-unit/build does not exist"
  bin/AdcSimulator --mode=delay_line_amp --event_rate=1000 --noise_rate=0.25
popd

