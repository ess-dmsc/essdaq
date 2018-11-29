#!/bin/bash

function errexit() {
  echo Error: $1
  exit 1
}

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR  &>/dev/null || errexit "directory $THISDIR does not exist"

  #get config variables
  . ../config/system.sh || errexit "Unable to read system.sh"

  UDPARG=""
  if [[ $EFU_UDP != "" ]]; then
    UDPARG="-p $EFU_UDP"
  fi

  MTUARG=""
  if [[ $EFU_MTU != "" ]]; then
    MTUARG="-u $EFU_MTU"
  fi

  if [[ $ESSDAQROOT != "" ]]; then
    CONFIG_FILE=$ESSDAQROOT/essdaq/detectors/$DETECTOR/config.ini
  else
    CONFIG_FILE=$HOME/essdaq/detectors/$DETECTOR/config.ini
  fi

  test -f $CONFIG_FILE || errexit "No config file: $CONFIG_FILE"

  pushd ./event-formation-unit/build &> /dev/null || errexit "directory ./event-formation-unit/build does not exist"
    #./bin/efu --read_config $CONFIG_FILE $UDPARG $MTUARG -b $KAFKA_IP -g $GRAFANA_IP $@ &>> $THISDIR/logfile.txt &
    ./bin/efu --read_config $CONFIG_FILE $UDPARG $MTUARG -b $KAFKA_IP -g $GRAFANA_IP --log_file $THISDIR/logfile.txt $@ &>> /dev/null &
  popd

popd
