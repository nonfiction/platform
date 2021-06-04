#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

if undefined $SWARM; then
  echo
  echo "Usage:  swarm inspect SWARM"
  echo
  exit 1
fi

if hasnt $SWARMFILE; then
  echo_stop "Swarm named $SWARM not found in $SWARMFILE"
  exit 1
fi

# Environment Variables
include "lib/env.sh"

PRIMARY=$(get_swarm_primary)
VOLUME_SIZE=$(get_volume_size $PRIMARY)
DROPLET_SIZE=$(get_droplet_size $PRIMARY)


INSPECT_ONLY=1
include "lib/process.sh"
