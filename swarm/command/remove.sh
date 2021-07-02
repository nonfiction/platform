#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"
verify_esh

if undefined $SWARM; then
  echo
  echo "Usage:  swarm remove SWARM"
  echo
  exit 1
fi

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

# Check if swarmfile exists
if hasnt $SWARMFILE; then
  echo_stop "Swarm named \"${SWARM}\" not found:"
  echo $SWARMFILE
  echo
  exit 1
fi

# Ensure we're on a different machine
if [ $SWARM = $(hostname -f) ]; then
  echo_stop "Cannot REMOVE swarm from a node within this same swarm."
  echo "Perform this command on a separate computer."
  echo
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


    # Check if this swarm has a load balancer
    lb_node="$(load_balancer_node)"
    lb_ip="$(get_load_balancer_ip)"

    if defined "$lb_node" && defined "$lb_ip"; then

      # Remove this load balancer's DNS records
      remove_record $lb_node
      remove_record "*.$lb_node"

      # Remove this swarm's load balancer
      remove_load_balancer $NODE

    fi


    # Lastly, delete the swarmfile
    rm $SWARMFILE
    echo_info "DELETED: ${SWARMFILE}"

  fi

else
  if ask "Droplet [${SWARM}] doesn't exist. Delete ${SWARMFILE}?"; then
    rm $SWARMFILE
    echo_info "DELETED: ${SWARMFILE}"
  fi
fi

# Remove docker context
if has docker; then
  if defined "$(docker context ls | grep root@$SWARM)"; then
    echo_next "Removing DOCKER CONTEXT: ${SWARM}"
    echo_run "docker context remove $NODE"
  fi
fi
