#!/bin/bash
ETHIF=$1

MYOS=$(uname)

#
###
#

function pingcheck()
{
  ping -c 1 -i 0.2 -W 1000 $1 &>/dev/null || errexit "unable to ping $1"
}

echo Network check started

pingcheck $EFU_IP
pingcheck $KAFKA_IP
pingcheck $DAQUIRI_IP
pingcheck $GRAFANA_IP

echo Network check PASSED
