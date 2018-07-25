#!/bin/bash

pushd ../event-formation-unit/build
./bin/udpgen_pcap -i 10.0.0.32 -t 100 -f $@


