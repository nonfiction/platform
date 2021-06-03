#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

if hasnt $SWARMFILE; then
  echo_stop "Swarm named $SWARM not found in $SWARMFILE"
  exit 1
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
