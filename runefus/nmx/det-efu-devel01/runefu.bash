#!/bin/bash

basedir=${EFUBASE:-/home/essdaq/essproj/event-formation-unit}
config=$PWD/config/nmx_2023_09_20.json
efu=$basedir/build/bin/nmx

local_kafka="127.0.0.1:9092"


kafka=$local_kafka
kafkacfg=""

grafana="127.0.0.1"
dataport=9000
cmdport=8888
region=9

. ../../checkandrun $@
