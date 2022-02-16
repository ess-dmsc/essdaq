#!/bin/bash

basedir=${EFUBASE:-/home/essdaq/essproj/event-formation-unit}
module=$basedir/build/modules/ttlmonitor.so
config=$basedir/src/modules/ttlmonitor/configs/lokimon.json
efu=$basedir/build/bin/efu
kafka="127.0.0.1:9092"
grafana="127.0.0.1"
dataport=9001
cmdport=8889
region=9

. ../../checkandrun -t loki_beam_monitor $@
