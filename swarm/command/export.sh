#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

if undefined $SWARM; then
  echo
  echo "Usage:  swarm export SWARM"
  echo
  exit 1
fi


# Check if swarmfile exists
if hasnt $SWARMFILE; then
  echo_stop "Swarm named \"${SWARM}\" not found:"
  echo $SWARMFILE
  echo
  exit 1

# Save to directory
else
  echo_main_alt "Which directory should this SWARMFILE be exported?"
  EXPORT_DIR="${PWD}"
  ask_input EXPORT_DIR
  EXPORT_DIR=$(ask_env EXPORT_DIR)
  mkdir -p $EXPORT_DIR
  EXPORT_FILE="${EXPORT_DIR}/$(echo $SWARM | tr '.' '_').sh"
  echo_run "cp ${SWARMFILE} ${EXPORT_FILE}" 
  echo_info "...done!"
  echo_next "Exported SWARMFILE to ${EXPORT_FILE}"
fi
