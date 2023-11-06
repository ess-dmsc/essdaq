#!/bin/bash

basedir=${EFUBASE:-/home/essdaq/essproj/event-formation-unit}
config=$PWD/config/cfg1/AMOR_config_20231104215334.json
efu=$basedir/build/bin/freia

local_kafka="127.0.0.1:9092"
psi_kafka="127.0.0.1:9092"
kafka=$local_kafka

grafana="127.0.0.1"
dataport=9000
cmdport=8888
region=9

. ../../checkandrun -t amor_detector $@
