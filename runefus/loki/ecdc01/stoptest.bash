#!/bin/bash

/home/essdaq/essproj/essdaq/runefus/stopefu 8888
/home/essdaq/essproj/essdaq/runefus/stopefu 8889
python /home/essdaq/fwscripts/stop_all_write_jobs.py
