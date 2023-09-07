#!/bin/bash

basedir=${EFUBASE:-/home/essdaq/essproj/event-formation-unit}
config=$basedir/src/modules/freia/config/amor.json
efu=$basedir/build/bin/freia
kafka="127.0.0.1:9092"
grafana="127.0.0.1"
dataport=9000
cmdport=8888
region=9

. ../../checkandrun $@
