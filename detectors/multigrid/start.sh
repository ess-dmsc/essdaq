#!/bin/bash

echo "START MULTIGRID"

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
  CONFIGARG="--file $(pwd)/config/${EFU_CONFIG}.json"
fi

startDaquiri

../../efu/efu_start.sh $CONFIGARG $@
sleep 1

if [[ $MVME_IP != "" ]]; then
  mvme/scripts/start_mvme.sh $MVME_IP
fi
