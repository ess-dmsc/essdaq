#!/bin/bash

function errexit()
{
  echo Error: $1
  exit 1
}

function detectos()
{
  echo "Detect OS and select install script"
  command -v grep  &>/dev/null || errexit "grep command does not exist"
  command -v cat   &>/dev/null || errexit "cat command does not exist"
  command -v uname &>/dev/null || errexit "uname command does not exist"

  cat /etc/centos-release 2>/dev/null | grep CentOS &>/dev/null && export SYSTEM=centos
  cat /etc/lsb-release 2>/dev/null    | grep Ubuntu &>/dev/null && export SYSTEM=ubuntu
  uname -a | grep Darwin &>/dev/null && export SYSTEM=macos
}

function installpkg()
{
  UBUNTUPKG=$1
  CENTOSPKG=${2:-$UBUNTUPKG}

  if [[ $UBUNTUPKG == "" ]]; then
    errexit "No install package specified"
  fi

  if [[ $SYSTEM == "ubuntu"]]; then
    apt-get install -y $UBUNTUPKG
  fi

  if [[ $SYSTEM == "centos"]]; then
    yum install -y $CENTOSPKG
  fi
}

detectos
