#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

yes | cp -rf ./config/* $HOME/
yes | cp -rf ./config/.config/* $HOME/.config/

