#!/bin/bash

ESSDAQROOT=$HOME/essproj

. $ESSDAQROOT/essdaq/config/mjc/common.sh

EFU_IP=$MJCWS_I
KAFKA_IP=$MJCWS_I
DAQUIRI_IP=$MJCWS_II
GRAFANA_IP=$ECDC_GRAFANA

UDP_ETH=enp0s25

DUMP_PATH=/tmp/essdaq
