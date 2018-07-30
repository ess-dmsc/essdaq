#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

./efu_start.sh --dumptofile $HOME/data/efu_dump/$@


