#!/bin/bash

echo "START SoNDe - DUMPING TO FILE"

# change to directory of script
cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null
export DETECTORDIR=$(pwd)

source ../../config/scripts/base.sh

#
# #
#

subdir=$1
fileprefix=$2

if [[ $1 == "" ]]; then
    echo Usage: dump_start.sh subdir file_prefix
    echo subdir will be created under $DUMP_PATH
    exit 0
fi

if [ ! -d $DUMP_PATH ]; then
    echo Directory $DUMP_PATH does not exist, exiting
    exit 0
fi

fullpath=$DUMP_PATH/$subdir

if [ ! -d $fullpath ]; then
    echo "$fullpath --> Folder does not exist --> It will be created"
    mkdir -p $fullpath &>/dev/null || errexit "unable to create directory $fullpath"
fi

echo dumping files to directory: $fullpath

./start.sh --dumptofile $fullpath/$fileprefix
