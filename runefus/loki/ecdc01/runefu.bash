#!/bin/bash

basedir=${EFUBASE:-/home/essdaq/essproj/event-formation-unit}
module=$basedir/build/modules/loki.so
config=$basedir/src/modules/loki/configs/STFCTestIII.json
efu=$basedir/build/bin/efu
kafka="127.0.0.1:9092"
grafana="127.0.0.1"
dataport=9000
cmdport=8888
region=9

. /home/essdaq/essproj/essdaq/runefus/checkandrun $@
