#!/bin/bash

echo "STOP EFU"

source ../../config/scripts/base.sh

echo "Stopping EFU by sending EXIT to $EFU_IP"
echo "EXIT" | nc $EFU_IP 8888
echo " "
