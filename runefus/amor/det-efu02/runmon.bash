#!/bin/bash

basedir=${EFUBASE:-/home/essdaq/essproj/event-formation-unit}
config=$basedir/src/modules/ttlmonitor/configs/freiamon.json
efu=$basedir/build/bin/ttlmonitor
kafka="127.0.0.1:9092"
grafana="127.0.0.1"
dataport=9010
cmdport=8889
region=9

. ../../checkandrun $@
