#!/bin/bash



function errexit() 
{
   echo Error: $1
   echo HW check failed
   exit 1
}

rmemsize=12582912
backlogsize=5000
sysctl -a 2>/dev/null | grep net.core.rmem_max | grep $rmemsize || errexit "rmem_max size incorrect"
sysctl -a 2>/dev/null | grep net.core.wmem_max | grep $rmemsize || errexit "wmem_max size incorrect"
sysctl -a 2>/dev/null | grep net.core.netdev.max_backlog | grep $backlogsize || errexit "max_backlog size incorrect"

ifconfig eno1 | grep eno1 | grep "mtu 9000" || errexit "eno1 MTU is not 9000 bytes"
ifconfig eno2 | grep eno2 | grep "mtu 9000" || errexit "eno2 MTU is not 9000 bytes"


echo HW check PASSED 
