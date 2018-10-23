#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../../config/system.sh

echo "START_NEW" | nc $DAQUIRI_IP 12345 -w 1
../../efu/efu_start.sh --file $THISDIR/MB16.json
#sleep 1
#mvme/scripts/start_mvme.sh $MVME_IP