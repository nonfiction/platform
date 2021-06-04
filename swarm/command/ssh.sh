#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

if undefined $SWARM; then
  echo
  echo "Usage:  swarm ssh SWARM [node]"
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
REPLICAS=$(get_swarm_replicas)

if defined $ARGS; then
  run $ARGS
else
  echo "$PRIMARY $REPLICAS" | args
fi
