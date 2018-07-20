#!/bin/bash

mvme_version="0.9.4.1"

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

sudo arp -s 10.0.0.5 00:00:56:15:30:2b
./mvme/mvme-$mvme_version-Linux-x64/mvme.sh

