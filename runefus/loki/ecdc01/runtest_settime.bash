#!/bin/bash

runtime=${1:-3600}
testname=${2:-no_test_name}
./runefu.bash --dumptofile /run/media/essdaq/T7/data/${testname} --nohwcheck -s $runtime &
./runmon.bash --dumptofile /run/media/essdaq/T7/data/${testname} --nohwcheck -s $runtime &
~/essproj/essdaq/capture_pcap.bash $testname
