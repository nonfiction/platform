#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

if undefined $SWARM; then
  echo
  echo "Usage:  swarm edit SWARM"
  echo
  exit 1
fi

if hasnt $SWARMFILE; then
  echo_stop "Swarm named $SWARM not found in $SWARMFILE"
  exit 1
else
  $EDITOR $SWARMFILE
fi
