#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"
verify_esh

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

if hasnt $SWARMFILE; then
  echo_stop "Swarm named $SWARM not found in $SWARMFILE"
  exit 1
fi

# Environment Variables
include "lib/env.sh"

# List nodes with swarm
if defined $SWARM; then

  local P0 P1 R0 R1
  P1="$(echo_color black/on_blue " P ")$(echo_color black/on_green " ✔︎ ")"
  P0="$(echo_color black/on_blue " P ")$(echo_color black/on_red " ✖︎ ")"
  R1="$(echo_color black/on_blue " R ")$(echo_color black/on_green " ✔︎ ")"
  R0="$(echo_color black/on_blue " R ")$(echo_color black/on_red " ✖︎ ")"

  for node in $(get_swarm_primary); do
    if droplet_ready $node; then
      echo "$P1 ${node}.${DOMAIN}"
    else
      echo "$P0 ${node}.${DOMAIN}"
    fi
  done

  for node in $(get_swarm_replicas); do
    if droplet_ready $node; then
      echo "$R1 ${node}.${DOMAIN}"
    else
      echo "$R0 ${node}.${DOMAIN}"
    fi
  done

# List all swarmfiles
else

  for swarm in $(ls "${XDG_DATA_HOME}/swarms" | args); do
    primary=$(droplet_by_tag "primary:$(slugify $swarm)" | awk '{print $2}')
    if defined $primary; then 
      echo "$(echo_color black/on_green " ✔︎ ") $swarm"
    else
      echo "$(echo_color black/on_red " ✖︎ ") $swarm"
    fi
  done

fi
