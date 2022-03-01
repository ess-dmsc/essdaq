#!/bin/bash

runtime=${1:3600}
testname=${1:no_test_name}

./runefu.bash $@ &
./runmon.bash $@ &
