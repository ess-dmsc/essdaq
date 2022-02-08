#!/bin/bash

basedir=${EFUBASE:-/home/essdaq/essproj/event-formation-unit}
module=$basedir/build/modules/freia.so
config=$basedir/src/modules/freia/configs/freia.json
efu=$basedir/build/bin/efu
kafka="127.0.0.1:9092"
grafana="172.30.242.21"
dataport=9000
cmdport=8888
region=5

. ../checkandrun $@
