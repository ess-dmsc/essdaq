#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../../config/system.sh
. ../../config/colors.sh

PATH=$PATH:/home/mg/epics/base-3.16.1/bin/linux-x86_64
export EPICS_CA_ADDR_LIST=128.219.165.154:5066
EPICS_IDLE=2
EPICS_RUNNING=8

sound_start() {
  play ./sounds/cow1.wav -q &> /dev/null
}

sound_stop() {
  play ./sounds/cat_growl.wav -q &> /dev/null
}

stop_daquiri() {
  echo "STOP" | nc $DAQUIRI_IP 12345 -w 1
  echo "SAVE" | nc $DAQUIRI_IP 12345 -w 1
  echo "CLOSE_OLDER 90" | nc $DAQUIRI_IP 12345 -w 1
}

start_essdaq() {
  echo -e "\n\n${BIWhite}========================================${NC}"
  echo -e "${BIWhite}============${BGreen}Starting ESSDAQ${BIWhite}=============${NC}"
  echo -e "${BIWhite}========================================${NC}"

  RunNumber=$(caget -t BL17:CS:RunControl:LastRunNumber 2>&1)
  energy=$(caget -t BL17:CS:Energy:Ei 2>&1)
  TCDelay=$(caget -t BL17:Det:TH:DlyDet:TCDelay 2>&1)

  echo -e "${BBlue}RunNumber=$RunNumber Energy=$energy TCDelay=$TCDelay${NC}\n"
  prepend="${RunNumber}_${energy}meV_${TCDelay}us_"
  daquiri_name="${RunNumber}_${energy}meV_$(date +%FT%H-%M-%S)"

  echo "START_NEW $daquiri_name" | nc $DAQUIRI_IP 12345 -w 1
  ../../efu/efu_start.sh --file $THISDIR/Sequoia_mappings.json --dumptofile $HOME/data/efu_dump/$prepend &> /dev/null
  sound_start
  mvme/scripts/start_mvme.sh $MVME_IP &> /dev/null

  sleep 5
  echo ""
}

stop_essdaq() {
  echo -e "\n\n${BIWhite}========================================${NC}"
  echo -e "${BIWhite}============${BRed}Stopping ESSDAQ${BIWhite}=============${NC}"
  echo -e "${BIWhite}========================================${NC}"

  mvme/scripts/stop_mvme.sh $MVME_IP &> /dev/null
  sound_stop
  ../../efu/efu_stop.sh &> /dev/null
  sleep 3
  stop_daquiri
  echo ""
}

echo ""

mvme_crashed=false

while true; do 
  epics_run_status=$(caget -t BL17:CS:RunControl:State 2>&1)
  pcharge=$(caget -t BL17:Det:PCharge:C 2>&1)

  (../../efu/event-formation-unit/utils/efushell/isefurunning.py -i $EFU_IP &> /dev/null)
  efu_status=$?
  efu_status_str="Idle"
  bus_glitches=0
  if [[ "$efu_status" -ne 1 ]]; then
    efu_status_str="Running"
  fi

  mvme_status=$(mvme/scripts/state.sh $MVME_IP 2>&1 | tail -n 1)

  efu_col="${Green}${efu_status_str}${NC}"
  if [[ "$efu_status_str" != "Running" ]]; then
    efu_col="${Red}${efu_status_str}${NC}"
  fi

  mvme_col="${Green}${mvme_status}${NC}"
  if [[ "$mvme_status" != "Running" ]]; then
    mvme_col="${Red}${mvme_status}${NC}"
  fi

  if [[ "$epics_run_status" -eq $EPICS_IDLE ]]; then
    echo -ne "\e[0K\r$(date +%F\ %T) SNS:${Red}Idle${NC} EFU:$efu_col MVME:$mvme_col                      "
  elif [[ "$epics_run_status" -eq $EPICS_RUNNING ]]; then
    echo -ne "\e[0K\r$(date +%F\ %T) SNS:${Green}Running${NC} EFU:$efu_col MVME:$mvme_col pcharge=$pcharge"
  else
    echo -e "\n$(date +%F\ %T) ${BRed}UNDEFINED epics_run_status:${NC}\n$epics_run_status\n"
  fi

  if [[ "$mvme_status" != "Idle" && "$mvme_status" != "Running" && "$mvme_status" != "Paused" && "$mvme_status" != "Starting" && "$mvme_status" != "Stopping" ]]; then
    if [ "$mvme_crashed" = false ] ; then
      mvme_crashed=true
      echo -e "\n***${BRed}MVME crash detected${NC}; status = $mvme_status; restarting\n"

      echo "Please restart MVME on marked machine" | mail -s "BL17: ESS DAQ failure" instrument_hall_coordinators@ornl.gov
      echo "MVME crashed" | mail -s "ESS DAQ status" martin.shetty@esss.se anton.khaplanov@esss.se

      stop_essdaq
    else
      sound_stop
    fi
    continue
  fi

  if [ "$mvme_crashed" = true ] ; then
    echo "MVME recovered" | mail -s "ESS DAQ status" martin.shetty@esss.se anton.khaplanov@esss.se
  fi

  mvme_crashed=false

  if [[ "$efu_status" -ne 1 ]]; then
    bus_glitches=$(../../efu/event-formation-unit/utils/efushell/getstat.py bus_glitches -i $EFU_IP)
  fi
  
  if [[ "$epics_run_status" -eq $EPICS_RUNNING && "$bus_glitches" -ge 500 ]]; then
    echo -ne "\n\n***${BRed}Bus glitch detected${NC}"
    stop_essdaq
  elif [[ "$epics_run_status" -eq $EPICS_RUNNING && "$efu_status_str" == "Idle" && "$mvme_status" == "Idle" ]]; then
    start_essdaq
  elif [[ "$epics_run_status" -eq $EPICS_RUNNING && "$efu_status_str" == "Idle" ]]; then
    echo -e "\n***${BRed}ESS daq state does not reflect SNS state${NC}"
    mvme/scripts/stop_mvme.sh $MVME_IP
    efupid=$(pgrep efu)
    if [ -n "$efupid" ]; then
      echo -e "${BRed}efu is actually still running; killing it${NC}"
      kill $efupid
    fi
    sound_stop
    stop_daquiri
  elif [[ "$epics_run_status" -eq $EPICS_RUNNING && "$mvme_status" != "Running" ]]; then
    echo -e "\n***${BRed}ESS daq state does not reflect SNS state${NC}"
    ../../efu/efu_stop.sh
    sound_stop
    stop_daquiri
  elif [[ "$epics_run_status" -eq $EPICS_IDLE && ( "$efu_status_str" != "Idle" || "$mvme_status" != "Idle" ) ]]; then
    stop_essdaq
  fi

  # Check for 'q' keypress *waiting very briefly*  and exit the loop, if found.
  read -t 0.5 -rN 1 && [[ $REPLY == 'q' ]] && break

done

echo -e "\n\n"
