#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

#get config variables
. ../../config/system.sh

#mvme/scripts/stop_mvme.sh $MVME_IP
#sleep 3
../../efu/efu_stop.sh
sleep 3
echo "STOP" | nc $DAQUIRI_IP 12345 -w 2
#echo "SAVE" | nc $DAQUIRI_IP 12345 -w 2
echo "CLOSE_OLDER 20" | nc $DAQUIRI_IP 12345 -w 1


