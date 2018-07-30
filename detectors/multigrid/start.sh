#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

#get config variables
. ../../config_variables.sh

../../efu/efu_dump_start.sh
sleep 3
mvme/scripts/start_mvme.sh $MVME_IP