#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../../config/system.sh

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

./start.sh --dumptofile $basepath/$prepend $2 $3

