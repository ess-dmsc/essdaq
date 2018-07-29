#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../config_variables.sh

../../event-formation-unit/utils/netstats/netstats.bash $GRAFANA_IP 2003 eno2

