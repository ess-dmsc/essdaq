#!/bin/bash

basedir=${EFUBASE:-/home/essdaq/essproj/event-formation-unit}
module=$basedir/build/modules/ttlmonitor.so
config=$basedir/src/modules/ttlmonitor/configs/lokimon.json
efu=$basedir/build/bin/efu
kafka="172.30.242.20:9092"
grafana="172.30.242.21"
dataport=9001
cmdport=8889
region=9

. ../../checkandrun -t loki_beam_monitor $@
