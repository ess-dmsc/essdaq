#!/bin/bash

# build with 1 less than total number of CPUS, minimum 1
NUMCPUS=$(cat /proc/cpuinfo | grep -c processor)
let NUMCPUS-=1
if [ "$NUMCPUS" -lt "1" ]; then
  NUMCPUS=1
fi

usessh=yes

EFU_IP=127.0.0.1
KAFKA_IP=127.0.0.1
GRAFANA_IP=127.0.0.1

MVME_IP=127.0.0.1

UDP_ETH=enp0s31f6

DETECTOR=multigrid

