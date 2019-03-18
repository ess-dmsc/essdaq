#!/bin/bash

. ./common.sh

case $SYSTEM in
    "ubuntu")
    echo "Installing for Ubuntu"
    ./install.sh auto
    ;;
    "centos")
    echo "Installing for CentOS"
    ./install_centos7.sh auto
    ;;
    "macos")
    echo "MacOS detected, no install scripts available"
    ;;
    *)
    echo "Unable to detect OS"
esac
