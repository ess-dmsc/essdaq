#!/bin/bash

dumpdir=$1
splittime=$2
fileprefix=$3
basepath=/home/multigrid/data

if [[ $1 == "" ]]; then
    echo Usage: dump_start.sh subdir split_time file_prefix
    echo subdir will be created under $basepath
    exit 0
fi

if [ ! -d $basepath ]; then
    echo Directory $dumpdir does not exist, exiting 
    exit 0
fi

fullpath=$basepath/$dumpdir

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

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../../config/system.sh

prepend=$fileprefix

echo "START_NEW" | nc $DAQUIRI_IP 12345 -w 1
../../efu/efu_start.sh --file $THISDIR/MB16.json --dumptofile $fullpath/$prepend --h5filesplit $splittime

