#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

. ./version.sh

./mvme-$mvme_version-Linux-x64/mvme.sh

