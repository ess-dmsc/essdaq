#!/bin/bash

os=$(uname)
if [[ $os == "Darwin" ]]; then
  echo "This script is targeted CentOS, not MacOS"
  exit 0
fi

function errexit() {
  echo error: $1
  echo "Try this first:"
  echo '> scl enable devtoolset-8 – bash'
  exit 0
}

g++ --version | grep "8.3" || errexit "devtoolset-8 not activated (gcc version not 8.3)"
