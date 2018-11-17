#!/bin/bash

function errexit {
    echo Error: $1
    exit 1
}

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../../config/system.sh || errexit "invalid config file"

./hwcheck.sh $UDP_ETH || errexit "hw check failed"

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
    mkdir -p $fullpath
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

echo "START_NEW" | nc $DAQUIRI_IP 12345 -w 1
../../efu/efu_start.sh --file $THISDIR/MB18Freia.json --dumptofile $fullpath/$prepend --h5filesplit $splittime

