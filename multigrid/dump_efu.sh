#!/bin/bash

pushd ../event-formation-unit/build
./bin/efu -d modules/mgmesytec --dumptofile /home/multigrid/data/$@


