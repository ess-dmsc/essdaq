#!/bin/bash

essdaqdir=${DAQDIR:-/home/essdaq/essproj/essdaq}
basedir=${EFUBASE:-/home/essdaq/essproj/event-formation-unit}
config=$basedir/src/modules/nmx/configs/nmx.json
efu=$basedir/build/bin/nmx
kafka="127.0.0.1:9092"
grafana="127.0.0.1"
dataport=9000
cmdport=8888
region=9

. $essdaqdir/runefus/checkandrun $@