#!/bin/bash

echo "START AdcReadout"

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../../config/system.sh

echo "START_NEW" | nc $DAQUIRI_IP 12345 -w 1
../../efu/efu_start.sh
#sleep 1

