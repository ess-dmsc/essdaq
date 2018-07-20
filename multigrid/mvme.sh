#!/bin/bash

mvme_version="0.9.4.1"

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

./mvme/mvme-$mvme_version-Linux-x64/mvme.sh

