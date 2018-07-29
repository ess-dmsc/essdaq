#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR
pushd ../../event-formation-unit/build
./bin/efu --read_config ~/essdaq/multigrid/config.ini $@ &> $THISDIR/logfile &

popd
popd
