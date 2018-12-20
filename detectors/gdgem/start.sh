#!/bin/bash

echo "START GDGEM"

# change to directory of script
$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null)

source ../../config/scripts/base.sh

systemChecks

#
# #
#

CALIBARG=""
if [[ $EFU_CALIB != "" ]]; then
  CALIBARG="--calibration $(pwd)/${EFU_CONFIG}_calib.json"
fi

CONFIGARG=""
if [[ $EFU_CONFIG != "" ]]; then
  CONFIGARG="--file $(pwd)/${EFU_CONFIG}_config.json"
fi

startDaquiri

../../efu/efu_start.sh  $CONFIGARG $CALIBARG $@
