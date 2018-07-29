#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

#get config variables
. ../../config_variables.sh

mvme/scripts/stop_mvme.sh $MVME_IP
sleep 3
../../efu/efu_stop.sh
