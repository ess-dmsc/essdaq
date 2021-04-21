#!/bin/bash

os=$(uname)
if [[ $os == "Darwin" ]]; then
  echo "This script is targeted CentOS, not MacOS"
  exit 0
fi

function errmsg() {
  echo error: $1
  echo "Try this:"
  echo '> cd /usr/bin'
  echo '> sudo rm cmake'
  echo '> sudo ln -s cmake3 cmake'
  exit 0
}

cmake --version | grep " 3." || errexit "cmake command does not link to cmake3"
