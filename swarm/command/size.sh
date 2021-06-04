#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

if undefined $SWARM; then
  echo
  echo "Usage:  swarm size SWARM [VOLUME_SIZE] [DROPLET_SIZE]"
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

  include "lib/process.sh"
  include "command/update.sh"
fi

