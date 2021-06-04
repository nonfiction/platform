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

# Environment Variables
include "lib/env.sh"

echo
for replica in $REPLICAS; do
  is_addition=
  for addition in $ADDITIONS; do
    if [ "$addition" = "$replica" ]; then
      is_addition=1
      echo "$(echo_color black/on_yellow " + ") ${replica}.${DOMAIN}"
    fi
  done
  if undefined $is_addition; then
    if droplet_ready $replica; then
      echo "$(echo_color black/on_green " ✔︎ ") ${replica}.${DOMAIN}"
    else
      echo "$(echo_color black/on_red " ✖︎ ") ${replica}.${DOMAIN}"
    fi
  fi
done

for removal in $REMOVALS; do
  echo "$(echo_color black/on_yellow " - ") ${removal}.${DOMAIN}"
done


if defined $ARGS; then

  undefined $REPLICAS && REPLICAS="-"
  include "lib/process.sh"
  include "command/update.sh"

fi
