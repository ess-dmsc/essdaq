#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

#get config variables
. ../config/system.sh

event-formation-unit/utils/netstats/netstats.bash $GRAFANA_IP 2003 $UDP_ETH

