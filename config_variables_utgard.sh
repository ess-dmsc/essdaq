#!/bin/bash

# build with 1 less than total number of CPUS, minimum 1
NUMCPUS=$(cat /proc/cpuinfo | grep -c processor)
let NUMCPUS-=1
if [ "$NUMCPUS" -lt "1" ]; then
  NUMCPUS=1
fi

usessh=yes

EFU_IP=10.0.0.32
KAFKA_IP=10.0.0.31
GRAFANA_IP=10.0.0.22

MVME_IP=10.0.0.21

UDP_ETH=eno2

DETECTOR=multigrid

