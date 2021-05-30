#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

if undefined $SWARM; then
  echo
  echo "Usage:  swarm size SWARM [DROPLET_SIZE]"
  echo
  exit 1
fi

if hasnt $SWARMFILE; then
  echo_stop "Swarm named $SWARM not found in $SWARMFILE"
  exit 1
fi

DROPLET_SIZE=$3
if undefined $DROPLET_SIZE; then
  PRIMARY=$(get_swarm_primary)
  get_droplet_size $PRIMARY
else
  include "command/process.sh"
  include "command/update.sh"
fi

