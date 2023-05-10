#!/bin/bash
prefix=${1:-run0}
rotate=1800
interface=ens2f0
tcpdump -i $interface udp -w /home/essdaq/exppcap/${prefix}_loki_%H%M%S.pcap -G $rotate
