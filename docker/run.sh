#!/bin/bash

BRANCH=${1:-master}
MODE=${2:-auto}

function errexit()
{
    echo Error: $1
    exit 1
}

git clone -b $BRANCH https://github.com/ess-dmsc/essdaq.git || errexit "cant clone essdaq branch $BRANCH"

if [[ $MODE == "auto" ]]; then
  cd essdaq || errexit "cant cd into essdaq"
  ./autoinstall.sh || errexit "autoinstall failed"
else
  echo "Call install scripts manually."
fi
