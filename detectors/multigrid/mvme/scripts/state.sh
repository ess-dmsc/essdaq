#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

python mvmectrl.py -p 13800 -c getState -i $@
