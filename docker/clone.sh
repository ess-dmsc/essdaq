#!/bin/bash

BRANCH=master

function errexit()
{
    echo Error: $1
    exit 1
}


git clone -b $BRANCH https://github.com/ess-dmsc/essdaq.git || errexit "cant clone essdaq branch $BRANCH"

cd essdaq || errexit "cant cd into essdaq"

./autoinstall.sh || errexit "autoinstall failed"
