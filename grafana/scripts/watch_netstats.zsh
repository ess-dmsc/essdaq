#!/bin/zsh
netstat_grab=$(netstat -s | grep "udp:" -A 18)
dropped_full_socket_buffers=$(echo $netstat_grab | grep "full socket buffers" | awk '{print $1}')
dropped_no_socket=$(echo $netstat_grab | grep "no socket" | awk '{print $1}')

echo "stats.udp.dropped_full_socket_buffers $dropped_full_socket_buffers $(date +%s)" | nc 127.0.0.1 2003
echo "stats.udp.dropped_no_socket $dropped_no_socket $(date +%s)" | nc 127.0.0.1 2003
