#!/bin/bash

measure=61
split=60
duration=90
repeats=45


function waitfor() {
 stop=$1
 while [[ 1 ]];
 do
    curr=$(date +%s)
    if (( $curr >= $stop )); then
       echo timeout $1 reached
       break
    else
       echo sleeping 1
       sleep 1
    fi
 done 
}


#t=$(($(date +%s) + 10))
#waitfor $t
#exit

echo start:   $start
echo split:   $split
echo measure: $measure
echo wait:    $wait
echo repeats: $repeats

echo initial sleep
sleep 10

start=$(date +%s)
echo starttime $start
stoptime=$((start + duration))
echo stoptime: $stoptime

i=1
while [[ 1 ]]; 
do
    if (($i >= $repeats + 1)) ; then
       echo done
       echo "########################################################"
       exit
    fi

    echo "################ Measurement $i ################################"
    echo $(date +%s) - measure for $measure seconds
     ./rundumpfor.sh CollimatedBeam  $split E-angularscan $measure

    echo $(date +%s) - waiting for $stoptime
    waitfor $stoptime

    stoptime=$((stoptime + duration))
    echo new stoptime $stoptime
    i=$((i + 1))
done
