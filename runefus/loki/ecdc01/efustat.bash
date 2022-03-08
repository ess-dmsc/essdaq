#!/bin/bash

basedir=${EFUBASE:-/home/essdaq/essproj/event-formation-unit}
efustat=$basedir/utils/efushell/efustats.py
cmdport=8888

. ../../checkandstat $@
