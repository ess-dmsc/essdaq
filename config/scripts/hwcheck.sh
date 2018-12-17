#!/bin/bash
ETHIF=$1

MYOS=$(uname)
rmemsize=12582912
backlogsize=5000

#
###
#

function errexit()
{
   echo Error: $1
   echo HW check failed
   exit 1
}

function setbuffersizes()
{
  echo "Setting buffersizes temporary. Consider doing this permanently"
  sudo sysctl -w net.core.rmem_max=$rmemsize
  sudo sysctl -w net.core.wmem_max=$rmemsize
  sudo sysctl -w net.core.netdev.max_backlog=$backlogsize
}

#
###
#

if [[ $ETHIF == "" ]]; then
   errexit "No Ethernet interface specified"
fi

ifconfig $ETHIF || errexit "ethernet interface [$ETHIF] does not exist"

ifconfig $ETHIF | grep $ETHIF | grep "mtu 9000" || errexit "ethif [$ETHIF] - MTU is not 9000 bytes"


if [[ $MYOS != "Darwin" ]] ;
then
  sysctl -a 2>/dev/null | grep net.core.rmem_max | grep $rmemsize || setbuffersizes

  sysctl -a 2>/dev/null | grep net.core.rmem_max | grep $rmemsize || errexit "rmem_max size incorrect"
  sysctl -a 2>/dev/null | grep net.core.wmem_max | grep $rmemsize || errexit "wmem_max size incorrect"
  sysctl -a 2>/dev/null | grep net.core.netdev.max_backlog | grep $backlogsize || errexit "max_backlog size incorrect"
else
  echo "Skipping receive buffer check for MacOS!!"
fi

echo HW check PASSED
