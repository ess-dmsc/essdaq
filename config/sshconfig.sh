#!/bin/bash

if [ "ssh -T git@github.com" ]; then
  usessh=yes
fi
