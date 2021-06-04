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


REPLICAS=$(get_swarm_replicas)

if defined $REPLICAS; then
  echo_stop "This swarm cannot be deleted until all replicas are first removed."
  echo_env REPLICAS
  exit 1
fi


# Deletions
if has_droplet $NODE; then

  if ask "Really DELETE droplet [${SWARM}]?"; then

    echo_next "Deleting in 5 seconds..."
    sleep 5

    # Delete DNS records 
    remove_record "${NODE}"
    remove_record "*.${NODE}"

    # Delete volume
    remove_volume "${NODE}"

    # Delete droplet
    remove_droplet "${NODE}"

    rm $SWARMFILE
    echo_info "DELETED: ${SWARMFILE}"

  fi

else
  if ask "Droplet [${SWARM}] doesn't exist. Delete ${SWARMFILE}?"; then
    rm $SWARMFILE
    echo_info "DELETED: ${SWARMFILE}"
  fi
fi
