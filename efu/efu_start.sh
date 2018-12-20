#!/bin/bash

echo "START EFU"

source ../../config/scripts/base.sh

#
# #
#

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

test -f $CONFIG_FILE || errexit "No config file: $CONFIG_FILE"

echo "Extra EFU args: $@"

pushd ../../efu/event-formation-unit/build &> /dev/null || errexit "directory ./event-formation-unit/build does not exist"
  ./bin/efu --read_config $CONFIG_FILE $UDPARG -b $KAFKA_IP:9092 -g $GRAFANA_IP --log_file $THISDIR/logfile.txt $@ 2>&1 > /dev/null &
popd
