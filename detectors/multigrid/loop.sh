#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../../config/system.sh

PATH=$PATH:/home/mg/epics/base-3.16.1/bin/linux-x86_64
export EPICS_CA_ADDR_LIST=128.219.165.154:5066
EPICS_IDLE=2
EPICS_RUNNING=8

start_essdaq() {
  echo ""
  echo "Starting ESSDAQ"

  RunNumber=$(caget -t BL17:CS:RunControl:LastRunNumber 2>&1)
  energy=$(caget -t BL17:CS:Energy:Ei 2>&1)
  TCDelay=$(caget -t BL17:Det:TH:DlyDet:TCDelay 2>&1)

  echo "RunNumber=$RunNumber Energy=$energy TCDelay=$TCDelay"
  prepend="${RunNumber}_${energy}meV_${TCDelay}us_"

  echo "START_NEW" | nc $DAQUIRI_IP 12345 -w 1
  ../../efu/efu_start.sh --file $THISDIR/Sequoia_mappings.json --dumptofile $HOME/data/efu_dump/$prepend
  play ./sounds/cow1.wav -q
  mvme/scripts/start_mvme.sh $MVME_IP

  sleep 5
  echo ""
}

stop_essdaq() {
  echo ""
  echo "Stopping ESSDAQ"
  mvme/scripts/stop_mvme.sh $MVME_IP
  play ./sounds/cat_growl.wav -q
  ../../efu/efu_stop.sh
  sleep 3
  echo "STOP" | nc $DAQUIRI_IP 12345 -w 2
  echo ""
}

echo ""

mvme_crashed=false

while true; do 
  epics_run_status=$(caget -t BL17:CS:RunControl:State 2>&1)
  pcharge=$(caget -t BL17:Det:PCharge:C 2>&1)
  (../../efu/event-formation-unit/utils/efushell/isefurunning.py -i $EFU_IP &> /dev/null)
  efu_status=$?
  efu_status_str="idle"
  bus_glitches=0
  if [[ "$efu_status" -ne 1 ]]; then
    efu_status_str="running"
    bus_glitches=$(../../efu/event-formation-unit/utils/efushell/getstat.py bus_glitches -i $EFU_IP)
  fi
  mvme_status=$(mvme/scripts/state.sh $MVME_IP 2>&1 | tail -n 1)

  if [[ "$epics_run_status" -eq $EPICS_IDLE ]]; then
    echo -ne "\e[0K\r $(date +%F\ %T) IDLE efu_status=$efu_status_str mvme_state=$mvme_status bus_glitches=$bus_glitches epics_run_status=$epics_run_status"
  elif [[ "$epics_run_status" -eq $EPICS_RUNNING ]]; then
    echo -ne "\e[0K\r $(date +%F\ %T) RUNNING efu_status=$efu_status_str mvme_state=$mvme_status bus_glitches=$bus_glitches epics_run_status=$epics_run_status pcharge=$pcharge"
  else
    echo ""
    echo "$(date +%FT%T) ***WARNING*** UNDEFINED epics_run_status=$epics_run_status"
    echo ""
  fi

  if [[ "$mvme_status" != "Idle" && "$mvme_status" != "Running" && "$mvme_status" != "Paused" && "$mvme_status" != "Starting" && "$mvme_status" != "Stopping" ]]; then
    if [ "$mvme_crashed" = false ] ; then
      mvme_crashed=true
      echo ""
      echo "bad mvme status = $mvme_status; restarting"
      echo ""

      echo "Please restart MVME on marked machine" | mail -s "BL17: ESS DAQ failure" instrument_hall_coordinators@ornl.gov
      echo "MVME crashed" | mail -s "ESS DAQ status" martin.shetty@esss.se
      echo "MVME crashed" | mail -s "ESS DAQ status" anton.khaplanov@esss.se

      stop_essdaq
    else
      play ./sounds/cat_growl.wav -q      
    fi
    continue
  fi

  if [ "$mvme_crashed" = true ] ; then
    echo ""
    echo "bad mvme status = $mvme_status; restarting"
    echo ""

    echo "MVME recovered" | mail -s "ESS DAQ status" martin.shetty@esss.se
    echo "MVME recovered" | mail -s "ESS DAQ status" anton.khaplanov@esss.se
  fi

  mvme_crashed=false
  
  if [[ "$epics_run_status" -eq $EPICS_RUNNING && "$bus_glitches" -ge 500 ]]; then
    echo " "
    echo "bus glitch detected bad_buffers = $bus_glitches; restarting"
    stop_essdaq
  elif [[ "$epics_run_status" -eq $EPICS_RUNNING && "$efu_status_str" == "idle" && "$mvme_status" == "Idle" ]]; then
    start_essdaq
  elif [[ "$epics_run_status" -eq $EPICS_RUNNING && "$efu_status_str" == "idle" ]]; then
    echo ""
    echo "ESS daq state does not reflect SNS state; restarting"
    mvme/scripts/stop_mvme.sh $MVME_IP
    echo "STOP" | nc $DAQUIRI_IP 12345 -w 2
    play ./sounds/cat_growl.wav -q
  elif [[ "$epics_run_status" -eq $EPICS_RUNNING && "$mvme_status" != "Running" ]]; then
    echo " "
    echo "ESS daq state does not reflect SNS state; restarting"
    ../../efu/efu_stop.sh
    play ./sounds/cat_growl.wav -q
    sleep 3
    echo "STOP" | nc $DAQUIRI_IP 12345 -w 2
  elif [[ "$epics_run_status" -eq $EPICS_IDLE && ( "$efu_status_str" != "idle" || "$mvme_status" != "Idle" ) ]]; then
    stop_essdaq
  fi

  # Check for 'q' keypress *waiting very briefly*  and exit the loop, if found.
  read -t 0.5 -rN 1 && [[ $REPLY == 'q' ]] && break

done

echo ""
