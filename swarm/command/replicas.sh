#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

if undefined $SWARM; then
  echo
  echo "Usage:  swarm replicas SWARM [ARGS]"
  echo
  exit 1
fi

if hasnt $SWARMFILE; then
  echo_stop "Swarm named $SWARM not found in $SWARMFILE"
  exit 1
fi

PRIMARY=$(get_swarm_primary)

REMOVALS=$(get_swarm_removals $ARGS)
ADDITIONS=$(get_swarm_additions $ARGS)

# Look up number of existing replicas in swarm, including additions, without removals
REPLICAS=$(get_swarm_replicas "$ADDITIONS" "$REMOVALS")

include "command/process.sh"
include "command/update.sh"
