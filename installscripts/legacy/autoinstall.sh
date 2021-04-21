#!/bin/bash

function detectos()
{
    echo "Detecting OS"
    cat /etc/centos-release 2>/dev/null | grep CentOS &>/dev/null && export SYSTEM=centos
    cat /etc/lsb-release 2>/dev/null    | grep Ubuntu &>/dev/null && export SYSTEM=ubuntu
    uname -a | grep Darwin &>/dev/null && export SYSTEM=macos
    echo "OS Detected: $SYSTEM"
}

detectos

case $SYSTEM in
    "ubuntu")
    echo "Installing for Ubuntu"
    ./install.sh auto
    ;;
    "centos")
    echo "Installing for CentOS"
    scl enable devtoolset-6 -- ./install_centos7.sh auto
    ;;
    "macos")
    echo "MacOS detected, no install scripts available"
    ;;
    *)
    echo "Unable to detect OS"
esac
