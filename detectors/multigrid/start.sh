#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../config/system.sh

../../efu/efu_dump_start.sh -f $THISDIR/cfg1.json
sleep 3
mvme/scripts/start_mvme.sh $MVME_IP