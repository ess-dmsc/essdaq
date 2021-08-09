#!/bin/bash

os=$(uname)
if [[ $os == "Darwin" ]]; then
  echo "This script is targeted CentOS, not MacOS"
  exit 0
fi

function errmsg() {
  echo "error: $1"
}

env | grep "(conan)" || errmsg "conan environment not activated"

conan --version | grep "1.3" || errmsg "bad conan version, expected 1.3*"

grep "compiler=gcc" ~/.conan/profiles/default || errmsg "please add compiler=gcc to ~/.conan/profiles/default"
grep "compiler.version=8" ~/.conan/profiles/default || errmsg "please add compiler.version=8 to ~/.conan/profiles/default"
grep "compiler.libcxx=libstdc++" ~/.conan/profiles/default || errmsg "please add compiler.libcxx=libstdc++ to ~/.conan/profiles/default"

conan remote list | grep "ess-dmsc" || errmsg "ess-dmsc not in remotes"
conan remote list | grep "bincrafters" || errmsg "bincrafters not in remotes"
conan remote list | grep "conan-center" || errmsg "conan-center not in remotes"
conan remote list | grep "conan-transit" || errmsg "conan-transit not in remotes"
conan remote list | grep "conan-community" || errmsg "conan-community not in remotes"
