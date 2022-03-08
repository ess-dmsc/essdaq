#!/bin/bash

basedir=${EFUBASE:-/home/essdaq/essproj/event-formation-unit}
module=$basedir/build/modules/loki.so
config=$basedir/src/modules/loki/configs/STFCTestIII.json
efu=$basedir/build/bin/efu
kafka="127.0.0.1:9092"
grafana="127.0.0.1"
dataport=9002
cmdport=8890
region=8

. ../../checkandrun $@
