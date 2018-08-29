#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

#get config variables
. ../../config/system.sh

mvme/scripts/stop_mvme.sh $MVME_IP
sleep 5
../../efu/efu_stop.sh
sleep 10
echo "STOP" | nc $DAQUIRI_IP 12345 -w 2
