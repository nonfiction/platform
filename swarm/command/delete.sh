#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

if undefined $SWARM; then
  echo
  echo "Usage:  swarm delete SWARM"
  echo
  exit 1
fi

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

if hasnt $SWARMFILE; then
  echo_stop "Swarm named $SWARM not found at $SWARMFILE"
  exit 1
fi

if undefined $NODE; then
  echo_stop "\$NODE is undefined!"
  exit 1
fi

if undefined $DOMAIN; then
  echo_stop "\$DOMAIN is undefined!"
  exit 1
fi


# if $DEFINED
#   REPLICAS=$(get_swarm_replicas)
#   echo $REPLICAS
#   echo "replicas"

# Deletions
if has_droplet $NODE; then

  if ask "Really DELETE droplet [${SWARM}]?"; then

    echo_next "Deleting..."

    # Delete DNS records 
    echo remove_record "${NODE}"
    echo remove_record "*.${NODE}"

    # Delete volume
    echo remove_volume "${NODE}"

    # Delete droplet
    echo remove_droplet "${NODE}"

    rm $SWARMFILE
    echo_info "DELETED: ${SWARMFILE}"

  fi

else
  if ask "Droplet [${SWARM}] doesn't exist. Delete ${SWARMFILE}?"; then
    rm $SWARMFILE
    echo_info "DELETED: ${SWARMFILE}"
  fi
fi
