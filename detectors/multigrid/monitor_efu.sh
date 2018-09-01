#!/bin/bash

    efupid=$(pgrep efu)
    if [ -n "$efupid" ]; then
      echo "efu is actually still running"
      kill $efupid
    else
      echo "efu is definitely not running"
    fi
