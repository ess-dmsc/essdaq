#!/bin/bash

#ensure that we are in the script directory
pushd $(dirname "${BASH_SOURCE[0]}")

yes | cp -rf $HOME/data/mesytec/*.analysis ./config/data/mesytec
yes | cp -rf $HOME/data/mesytec/*.vme ./config/data/mesytec
yes | cp -rf $HOME/data/mesytec/*.ini ./config/data/mesytec
yes | cp -rf $HOME/.config/mesytec ./config/.config
