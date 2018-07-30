#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

#get config variables
. ../config_variables.sh

echo "EXIT" | nc $EFU_IP 8888
echo " "

