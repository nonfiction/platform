#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"
verify_esh

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

if undefined $SWARM; then
  echo
  echo "Usage:  swarm size SWARM [VOLUME_SIZE] [DROPLET_SIZE]"
  echo
  exit 1
fi

# Check if swarmfile exists
if hasnt $SWARMFILE; then
  echo_stop "Swarm named \"${SWARM}\" not found:"
  echo $SWARMFILE
  echo
  exit 1
fi

# Ensure we're on a different machine
if [ $SWARM = $(hostname -f) ]; then
  echo_stop "Cannot change swarm's SIZE from a node within this same swarm."
  echo "Perform this command on a separate computer."
  echo
  exit 1
fi

# Get primary and its size
PRIMARY=$(get_swarm_primary)
VOLUME_SIZE=$(get_volume_size $PRIMARY)
DROPLET_SIZE=$(get_droplet_size $PRIMARY)

# Environment Variables
include "lib/env.sh"

if undefined $ARGS; then
  count=$((1 + $(echo $REPLICAS | wc -w)))
  [ "$count" = "1" ] && count="Single"
  echo_next "${count}-node swarm..."
  echo "$(echo_env VOLUME_SIZE) (GB)"
  echo "$(echo_env DROPLET_SIZE) (choose slug listed below)"
  echo
  echo_droplet_prices
else

  for arg in $ARGS; do
    if [[ $arg =~ ^[0-9]+$ ]]; then 
      export VOLUME_SIZE=$arg
    else
      export DROPLET_SIZE=$arg
    fi
  done

  echo "$(echo_env VOLUME_SIZE)"
  echo "$(echo_env DROPLET_SIZE)"

  RESIZE=1

  include "command/provision.sh"
  include "command/deploy.sh"
fi

