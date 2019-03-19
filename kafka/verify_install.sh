#!/bin/bash

echo checking that kafka process is running
ps aux | grep java | grep kafka &>/dev/null || exit 1

echo checking that zookeeper process is running
ps aux | grep java | grep zookeeper &>/dev/null || exit 1

#echo check that kafka is listening on port 9092
#netstat -an | grep tcp |  grep 9092 | grep LISTEN &>/dev/null || exit 1
