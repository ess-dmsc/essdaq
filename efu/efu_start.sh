#!/bin/bash

echo "START EFU"

source ../../config/scripts/base.sh

#
# #
#

# This is no good, cannot differentiate other processes that may have "efu" somewhere in the string
# don't start if EFU is running
#ps aux | grep -v grep | grep efu && errexit "EFU is already running on this machine"

UDPARG=""
if [[ $EFU_UDP != "" ]]; then
  UDPARG="-p $EFU_UDP"
fi

if [[ $ESSDAQROOT != "" ]]; then
  echo "Using custom essdaq location: $ESSDAQROOT"
  CONFIG_FILE=$ESSDAQROOT/essdaq/detectors/$DETECTOR/config.ini
else
  echo "Using default essdaq location"
  CONFIG_FILE=$HOME/essdaq/detectors/$DETECTOR/config.ini
fi

NOHWARG=""
if [[ $NOHW != "" ]]; then
  NOHWARG="--nohwcheck"
fi

test -f $CONFIG_FILE || errexit "No config file: $CONFIG_FILE"

echo "Extra EFU args: $@"

pushd ../../efu/event-formation-unit/build &> /dev/null || errexit "directory ./event-formation-unit/build does not exist"
  if [ -z "$DEBUG" ]; then
    ./bin/efu --read_config $CONFIG_FILE $UDPARG $NOHWARG -b $KAFKA_IP:9092 -g $GRAFANA_IP --log_file ../../logfile.txt $@ 2>&1 > /dev/null &
  else
    ./bin/efu --read_config $CONFIG_FILE $UDPARG $NOHWARG -b $KAFKA_IP:9092 -g $GRAFANA_IP $@
  fi
popd
