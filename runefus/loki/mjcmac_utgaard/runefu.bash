#!/bin/bash

basedir=${EFUBASE:-/home/essdaq/essproj/event-formation-unit}
module=$basedir/build/modules/loki.so
config=$basedir/src/modules/loki/configs/STFCTestIII.json
efu=$basedir/build/bin/efu
kafka="172.30.242.20:9092"
grafana="172.30.242.21"
dataport=9000
cmdport=8888
region=9

. ../../checkandrun $@
