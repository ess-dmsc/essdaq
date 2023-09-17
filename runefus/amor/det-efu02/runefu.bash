#!/bin/bash

basedir=${EFUBASE:-/home/essdaq/essproj/event-formation-unit}
config=$PWD/config/amor.json
efu=$basedir/build/bin/freia

local_kafka="127.0.0.1:9092"
psi_kafka="127.0.0.1:9092"
staging_kafka="10.102.80.32:8093"
kafka=$staging_kafka
kafkacfg=$PWD/config/kafkacfg.json

grafana="127.0.0.1"
dataport=9000
cmdport=8888
region=9

. ../../checkandrun $@
