#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

if undefined $SWARM; then
  echo
  echo "Usage:  $CMD_NAME import SWARMFILE"
  echo
  exit 1
fi

# Redefine these in case imported swarmfile is not in the current directory
SWARMPATH=$SWARM
SWARM=$(basename $SWARM | awk '{sub(/\.sh$/,"")}1' | tr '[:upper:]' '[:lower:]' | tr '_' '.' )
NODE=$(node_from_fqdn $SWARM);
SWARMFILE="${XDG_DATA_HOME}/swarms/${SWARM}"

# Check if swarmfile exists
if has $SWARMFILE; then
  echo_stop "Swarm named \"${SWARM}\" already exists:"
  echo $SWARMFILE
  echo
  exit 1
fi

# Move swarmfile to swarms directory
echo_next "Importing SWARMFILE: ${SWARM}"
echo_run "mv ${SWARMPATH} ${XDG_DATA_HOME}/swarms/${SWARM}"

# Environment Variables
include "lib/env.sh"

# Add imported swarm as docker context
if has docker; then
  echo_next "Creating DOCKER CONTEXT: ${SWARM}"
  echo_run "docker context create $NODE --default-stack-orchestrator=swarm --docker host=ssh://root@${SWARM} --description $ROLE"
fi
