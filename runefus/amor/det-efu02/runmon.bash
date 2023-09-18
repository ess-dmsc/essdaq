#!/bin/bash

basedir=${EFUBASE:-/home/essdaq/essproj/event-formation-unit}
config=$PWD/config/freiamon.json
efu=$basedir/build/bin/ttlmonitor

local_kafka="127.0.0.1:9092"
psi_kafka="127.0.0.1:9092"
kafka=$local_kafka

grafana="127.0.0.1"
dataport=9010
cmdport=8889
region=9

. ../../checkandrun $@
