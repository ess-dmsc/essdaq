#!/bin/bash

echo "START GDGEM"

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../../config/system.sh

CALIBARG=""
if [[ $EFU_CALIB != "" ]]; then
  CALIBARG="--calibration $THISDIR/${EFU_CONFIG}_calib.json"
fi

echo "START_NEW" | nc $DAQUIRI_IP 12345 -w 1
../../efu/efu_start.sh --file $THISDIR/${EFU_CONFIG}_config.json $CALIBARG $@
#sleep 1

