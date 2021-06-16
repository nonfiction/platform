#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

if undefined $SWARM; then
  echo
  echo "Usage:  swarm edit SWARM"
  echo
  exit 1
fi


# Check if swarmfile exists
if hasnt $SWARMFILE; then
  echo_stop "Swarm named \"${SWARM}\" not found:"
  echo $SWARMFILE
  echo
  exit 1

# Launch editor
else
  $EDITOR $SWARMFILE
fi
