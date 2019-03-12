#!/bin/bash

echo "Detect OS and select install script"

function errexit()
{
    echo Error: $1
    exit 1
}

function detectos()
{
    cat /etc/centos-release 2>/dev/null | grep CentOS &>/dev/null && SYSTEM=centos
    uname -a | grep Ubuntu &>/dev/null && SYSTEM=ubuntu
    uname -a | grep Darwin &>/dev/null && SYSTEM=macos
}

command -v grep  &>/dev/null || errexit "grep command does not exist"
command -v cat   &>/dev/null || errexit "cat command does not exist"
command -v uname &>/dev/null || errexit "uname command does not exist"

detectos

case $SYSTEM in
    "ubuntu")
    echo "Installing for Ubuntu"
    ./install.sh
    ;;
    "centos")
    echo "Installing for CentOS"
    ./install_centos7.sh
    ;;
    "macos")
    echo "MacOS detected, no install scripts available"
    ;;
    *)
    echo "Unable to detect OS"
esac 
