#!/bin/bash

echo "START Multi-Blade - DUMPING TO FILE"

# change to directory of script
cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null
export DETECTORDIR=$(pwd)

source ../../config/scripts/base.sh

#
# #
#

subdir=$1
splittime=$2
fileprefix=$3

if [[ $1 == "" ]]; then
    echo Usage: dump_start.sh subdir split_time file_prefix
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

if [[ $splittime == "0" ]]; then
    echo Do NOT time split files
else
    echo Split files every $splittime seconds
fi

RUNID=$(./getrunid)
echo "Runid from Amor: $RUNID"

prepend=$RUNID-$fileprefix

./start.sh --dumptofile $fullpath/$prepend --h5filesplit $splittime
