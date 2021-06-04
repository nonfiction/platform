#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

if undefined $SWARM; then
  echo
  echo "Usage:  swarm primary SWARM [ARGS]"
  echo
  exit 1
fi

if hasnt $SWARMFILE; then
  echo_stop "Swarm named $SWARM not found in $SWARMFILE"
  exit 1
fi

PROMOTED=$3
PRIMARY=$(get_swarm_primary)

# Environment Variables
include "command/env.sh"

if undefined $PROMOTED; then
  if droplet_ready $PRIMARY; then
    echo "$(echo_color black/on_green " ✔︎ ") ${PRIMARY}.${DOMAIN}"
  else
    echo "$(echo_color black/on_red " ✖︎ ") ${PRIMARY}.${DOMAIN}"
  fi
  exit

else
  DEMOTED=$PRIMARY

  # Reassign PRIMARY for display
  PRIMARY=$PROMOTED

  # Add old primary to replicas, remove new primary from replicas
  REPLICAS=$(get_swarm_replicas $DEMOTED $PROMOTED)

  include "command/process.sh"
  include "command/update.sh"
fi
