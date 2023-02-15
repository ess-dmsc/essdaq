#!/bin/bash

basedir=${EFUBASE:-/home/essdaq/essproj/event-formation-unit}
module=$basedir/build/modules/mbcaen.so
config=$basedir/../efu-legacy-modules/multiblade/configs/AmorB.json
efu=$basedir/build/bin/efu
kafka="127.0.0.1:9092"
grafana="127.0.0.1"
dataport=9000
cmdport=8888
region=9

. ../../checkandrun $@
