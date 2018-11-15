#!/bin/bash


a=$1
b=$2
c=$3
runfor=$4


./dump_start.sh $a $b $c
echo running for $runfor seconds, started at $(date)
sleep $runfor
./stop.sh
echo stopped
