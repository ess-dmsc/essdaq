#!/bin/bash

echo "STOP DREAM"

# change to directory of script
cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null
export DETECTORDIR=$(pwd)

source ../../config/scripts/base.sh

#
# #
#

../../efu/efu_stop.sh
sleep 3

stopDaquiri
