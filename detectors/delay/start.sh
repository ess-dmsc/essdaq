#!/bin/bash

echo "START AdcReadout"

# change to directory of script
cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null
export DETECTORDIR=$(pwd)

source ../../config/scripts/base.sh

systemChecks

#
# #
#

startDaquiri
../../efu/efu_start.sh $@
#sleep 1
