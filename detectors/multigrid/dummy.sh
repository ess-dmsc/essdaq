#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

#get config variables
. ../../config/colors.sh

  echo -e "\n\n"
  echo -e "${BIWhite}========================================${NC}"
  echo -e "${BIWhite}============${BGreen}Starting ESSDAQ${BIWhite}=============${NC}"
  echo -e "${BIWhite}========================================${NC}"
  echo -e ""

  echo -e "\n\n"
  echo -e "${BIWhite}========================================${NC}"
  echo -e "${BIWhite}============${BRed}Stopping ESSDAQ${BIWhite}=============${NC}"
  echo -e "${BIWhite}========================================${NC}"
  echo -e ""
