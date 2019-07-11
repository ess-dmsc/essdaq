#!/bin/bash

echo "START DREAM"

# change to directory of script
cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null
export DETECTORDIR=$(pwd)

source ../../config/scripts/base.sh

systemChecks

#
# #
#

CONFIGARG=""
if [[ $EFU_CONFIG != "" ]]; then
  CONFIGARG="--file $(pwd)/${EFU_CONFIG}.json"
fi

startDaquiri

../../efu/efu_start.sh $CONFIGARG $@
sleep 1

