#!/bin/bash

function errexit {
    echo Error: $1
    exit 1
}

echo "START GDGEM"

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR &>/dev/null|| errexit "Unable to cd into directory $THISDIR"

#get config variables
. ../../config/system.sh || errexit "invalid system script"

. ../../config/scripts/hwcheck.sh $UDP_ETH

CALIBARG=""
if [[ $EFU_CALIB != "" ]]; then
  CALIBARG="--calibration $THISDIR/${EFU_CONFIG}_calib.json"
fi

CONFIGARG=""
if [[ $EFU_CONFIG != "" ]]; then
  CONFIGARG="--file $THISDIR/${EFU_CONFIG}_config.json"
fi

echo "START_NEW" | nc $DAQUIRI_IP 12345 -w 1
../../efu/efu_start.sh  $CONFIGARG $CALIBARG $@
#sleep 1
