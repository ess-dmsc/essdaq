#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../../config/system.sh

echo ""
while true; do 

  glitch=0

  echo -ne "\e[0K\r $(date +%F\ %T) glitches=$glitch"
  
  # Check for 'q' keypress *waiting very briefly*  and exit the loop, if found.
  read -t 0.01 -rN 1 && [[ $REPLY == 'q' ]] && break

done


