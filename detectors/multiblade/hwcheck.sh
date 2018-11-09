#!/bin/bash

function errexit()
{
   echo Error: $1
   echo HW check failed
   exit 1
}


MYOS=$(uname)

ETHIF=$1

if [[ $ETHIF == "" ]]; then
   errexit "No Ethernet interface specified"
fi

rmemsize=12582912
backlogsize=5000
if [[ $MYOS != "Darwin"]];
then
  sysctl -a 2>/dev/null | grep net.core.rmem_max | grep $rmemsize || errexit "rmem_max size incorrect"
  sysctl -a 2>/dev/null | grep net.core.wmem_max | grep $rmemsize || errexit "wmem_max size incorrect"
  sysctl -a 2>/dev/null | grep net.core.netdev.max_backlog | grep $backlogsize || errexit "max_backlog size incorrect"
else
  echo "Skipping receive buffer check for MacOS!!"
fi

ifconfig $ETHIF | grep $ETHIF | grep "mtu 9000" || errexit "$ETHIF MTU is not 9000 bytes"


echo HW check PASSED
