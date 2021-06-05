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

PRIMARY=$(get_swarm_primary)

# Environment Variables
include "lib/env.sh"

if undefined $ARGS; then
  if droplet_ready $PRIMARY; then
    echo "$(echo_color black/on_green " ✔︎ ") ${PRIMARY}.${DOMAIN}"
  else
    echo "$(echo_color black/on_red " ✖︎ ") ${PRIMARY}.${DOMAIN}"
  fi
  exit
else

  PROMOTED=$(node_from_fqdn $ARGS)

  DEMOTED=$PRIMARY

  # Reassign PRIMARY for display
  PRIMARY=$PROMOTED

  if [ "$DEMOTED" = "$PROMOTED" ]; then
    echo_stop "$PROMOTED is already primary."
    exit 1
  fi

  # Ensure all primary and replacement are ready
  for node in $PRIMARY $ARGS; do
    if droplet_ready $node; then
      echo "$(echo_color black/on_green " ✔︎ ") ${node}.${DOMAIN}"
    else
      echo "$(echo_color black/on_red " ✖︎ ") ${node}.${DOMAIN}"
      echo_stop "$node is not available."
      exit 1
    fi
  done

  # Add old primary to replicas, remove new primary from replicas
  REPLICAS=$(get_swarm_replicas $DEMOTED $PROMOTED)

  include "command/provision.sh"
  include "command/deploy.sh"
  k
fi
