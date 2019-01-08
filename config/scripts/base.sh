#!/bin/bash

if [ ! -d "$DETECTORDIR" ]; then
  echo "Error: required variable DETECTORDIR not set"
  exit 1
fi

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
  if [[ $NOHW == "" ]]; then
    . $DETECTORDIR/../../config/scripts/hwcheck.sh $UDP_ETH
    . $DETECTORDIR/../../config/scripts/nwcheck.sh
  fi
}

#
# #
#

# get config variables
. $DETECTORDIR/localconfig.sh || errexit "no local configuration"
. $DETECTORDIR/../../config/system.sh || errexit "invalid system script"
