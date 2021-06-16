#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"
verify_esh

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

if undefined $SWARM; then
  echo
  echo "Usage:  swarm ssh SWARM [node]"
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

PRIMARY=$(get_swarm_primary)
REPLICAS=$(get_swarm_replicas)

# Environment Variables
include "lib/env.sh"

if defined $ARGS; then
  run $ARGS
else
  echo "$PRIMARY $REPLICAS" | args
fi
