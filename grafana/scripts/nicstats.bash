#!/bin/bash


while [[ 1 ]];
do

timestamp=$(date +%s)
ethtool_grab=$(ethtool -S ens2f0)

rx_packets=$(echo "$ethtool_grab" | grep "rx_packets:" | awk '{print $2}')
rx_bytes=$(echo "$ethtool_grab" | grep "rx_bytes:" | awk '{print $2}')

echo "stats.ethtool.rx_packets ${rx_packets} $timestamp" | nc 127.0.0.1 2003
echo "stats.ethtool.rx_bytes ${rx_bytes} $timestamp" | nc 127.0.0.1 2003

echo "stats.ethtool.rx_packets ${rx_packets} $timestamp"
echo "stats.ethtool.rx_bytes ${rx_bytes} $timestamp"

sleep 1
done