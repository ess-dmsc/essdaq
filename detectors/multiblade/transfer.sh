#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

#get config variables
. ../../config/system.sh

scp $1 mb@$JADAQ_IP:$JADAQ_DATA_DIR
