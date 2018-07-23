#!/bin/bash

pushd ../event-formation-unit/build
./bin/efu --read_config ~/essdaq/multigrid/config.ini $@


