#!/bin/bash

echo "STOP MULTIGRID"

# change to directory of script
cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null
export DETECTORDIR=$(pwd)

source ../../config/scripts/base.sh

#
# #
#

if [[ $MVME_IP != "" ]]; then
  mvme/scripts/stop_mvme.sh $MVME_IP
  sleep 3
fi

../../efu/efu_stop.sh
sleep 3

stopDaquiri
saveDaquiri
