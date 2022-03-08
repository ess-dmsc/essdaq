#!/bin/bash
netstat_grab=$(netstat -s | grep "Udp:" -A 6)
buffer_errors=$(echo "$netstat_grab" | grep "receive buffer error" | awk '{print $1}')
unknown_port=$(echo "$netstat_grab" | grep "unknown port" | awk '{print $1}')
echo "stats.udp.buffererrors $buffer_errors $(date +%s)" | nc 127.0.0.1 2003
echo "stats.udp.unknownport $unknown_port $(date +%s)" | nc 127.0.0.1 2003
