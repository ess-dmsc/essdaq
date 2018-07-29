#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

. ./version.sh

mvme_file="mvme-$mvme_version-Linux-x64"
curl -LO http://www.mesytec.com/downloads/mvme/$mvme_file.tar.bz2
bzip2 -d ./$mvme_file.tar.bz2
tar xvf ./$mvme_file.tar
rm -f ./$mvme_file.tar
rm ./$mvme_file/libz.so.1

#grep -q -F 'sudo arp -s 10.0.0.5 00:00:56:15:30:2b"' $HOME/.bashrc || echo 'sudo arp -s 10.0.0.5 00:00:56:15:30:2b' >> $HOME/.bashrc

sudo ./arp.sh

yes | cp -rf ./mvme.desktop $HOME/Desktop/
echo "Exec=$THISDIR/mvme.sh" >> $HOME/Desktop/mvme.desktop
echo "Icon=$THISDIR/mvme.ico" >> $HOME/Desktop/mvme.desktop

./load_config.sh
