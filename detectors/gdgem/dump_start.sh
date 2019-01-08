#!/bin/bash

echo "START Gd-GEM - DUMPING TO FILE"

# change to directory of script
cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null
export DETECTORDIR=$(pwd)

source ../../config/scripts/base.sh

#
# #
#

fileprefix=$1
basepath=$DUMP_PATH

if [[ $1 == "" ]]; then
    echo Usage: dump_start.sh file_prefix
    exit 0
fi

if [ ! -d $basepath ]; then
    echo Directory $basepath does not exist, exiting
    exit 0
fi

prepend=$fileprefix

./start.sh --dumptofile $basepath/$prepend
