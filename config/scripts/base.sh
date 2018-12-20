#!/bin/bash

DETECTORDIR=$1

#
###
#
function errexit {
    echo Error: $1
    echo exiting ...
    exit 1
}

function startDaquiri()
{
  echo "start Daquiri acquisition"
  echo "START_NEW" | nc $DAQUIRI_IP 12345 -w 1
}

function stopDaquiri()
{
  echo Stopping Daquiri ...
  echo "STOP" | nc $DAQUIRI_IP 12345 -w 2
}

function saveDaquiri()
{
  echo "SAVE" | nc $DAQUIRI_IP 12345 -w 2
}

function closeDaquiri()
{
  OLDER_THAN=$1
  echo "CLOSE_OLDER $1" | nc $DAQUIRI_IP 12345 -w 1
}

function systemChecks()
{
. ../../config/scripts/hwcheck.sh $UDP_ETH
. ../../config/scripts/nwcheck.sh
}

#get config variables
. ./localconfig.sh || errexit "no local configuration"
. ../../config/system.sh || errexit "invalid system script"
