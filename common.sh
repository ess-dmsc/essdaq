#!/bin/bash

function errexit()
{
  echo Error: $1
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
