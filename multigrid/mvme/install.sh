#!/bin/bash

mvme_version="0.9.4.1"

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

mvme_file="mvme-$mvme_version-Linux-x64"
curl -LO http://www.mesytec.com/downloads/mvme/$mvme_file.tar.bz2
bzip2 -d ./$mvme_file.tar.bz2
tar xvf ./$mvme_file.tar
rm -f ./$mvme_file.tar
rm ./$mvme_file/libz.so.1

yes | cp -rf ./config/* $HOME/
yes | cp -rf ./config/.config/* $HOME/.config/
