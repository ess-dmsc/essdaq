#!/bin/bash

testname=${1:-no_test_name_}
nohup /home/essdaq/essproj/essdaq/runefus/loki/ecdc01/runefu.bash --dumptofile /run/media/essdaq/T7/data/${testname} --nohwcheck &
nohup /home/essdaq/essproj/essdaq/runefus/loki/ecdc01/runmon.bash --dumptofile /run/media/essdaq/T7/data/${testname} --nohwcheck &
#nohup python ~/fwscripts/run_file_writer.py $testname &
nohup python ~/fwscripts/run_file_writer.py $testname &
