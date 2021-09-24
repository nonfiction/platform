#!/bin/bash # Bash helper functions
include "lib/helpers.sh"
verify_esh

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

if undefined $SWARM; then
  echo
  echo "Usage:  $CMD_NAME provision SWARM [ARGS]"
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

# Primary usually matches swarm name (but it doesn't have to)
PRIMARY=$(get_swarm_primary)
has_droplet $PRIMARY && HAS_PRIMARY=1

# If primary exists, grab volume & droplet size
if undefined $RESIZE; then

  # Existing swarm gets sizes from primary
  if defined $HAS_PRIMARY; then
    VOLUME_SIZE=$(get_volume_size $PRIMARY)
    DROPLET_SIZE=$(get_droplet_size $PRIMARY)


  # New swarm needs a starting size
  else
    echo_main_alt "Provisioning NEW swarm..."
    echo_droplet_prices

    ask_input DROPLET_SIZE
    DROPLET_SIZE=$(ask_env DROPLET_SIZE s-1vcpu-1gb)
    echo_env DROPLET_SIZE

    ask_input VOLUME_SIZE
    VOLUME_SIZE=$(ask_env VOLUME_SIZE 10)
    echo_env VOLUME_SIZE

    if undefined "$DROPLET_SIZE" || undefined "$VOLUME_SIZE"; then
      echo_stop "Invalid size selection"
      echo
      exit 1
    fi
  fi

fi

# Environment Variables
include "lib/env.sh"


# Add or remove replicas
REMOVALS=$(get_swarm_removals $ARGS)
ADDITIONS=$(get_swarm_additions $ARGS)

# Look up number of existing replicas in swarm, including additions, without removals
REPLICAS=$(get_swarm_replicas "$ADDITIONS" "$REMOVALS")

# If primary doesn't exist yet, count that as an addition
if undefined $HAS_PRIMARY; then
  ADDITIONS="$(echo "$PRIMARY $ADDITIONS" | args)"
fi


# Ensure new droplets have a volume size no smaller than primary's volume 
# This is because a replicated volume will only be as largest as it's smallest node
if defined $HAS_PRIMARY; then
  primary_volume_size=$(get_volume_size $PRIMARY)
  [ "$VOLUME_SIZE" -lt "$primary_volume_size" ] && VOLUME_SIZE=$primary_volume_size
fi

NODES="$(echo "${PRIMARY} ${REPLICAS}" | xargs)"


# Count the number of nodes in this swarm
count=$((1 + $(echo $REPLICAS | wc -w)))
[ "$count" = "1" ] && count="" || count="[x${count}]"
if defined $INSPECT_ONLY; then
  echo_main "INSPECT ${SWARM} ${count}"
else
  echo_main "PROVISION ${SWARM} ${count}"
fi
echo_env PRIMARY
defined $REPLICAS  && echo_env REPLICAS
defined $REMOVALS  && echo_env REMOVALS
defined $ADDITIONS && echo_env ADDITIONS
echo_env VOLUME_SIZE
echo_env DROPLET_SIZE

if [ "$ROLE" = "dev" ]; then
  echo_next "Workspace Config"
  echo_line green
  echo_env GIT_USER_NAME
  echo_env GIT_USER_EMAIL
  echo_env GITHUB_USER
  echo_env GITHUB_TOKEN
  echo_env CODE_PASSWORD
  echo_env SUDO_PASSWORD
  echo_env DB_HOST
  echo_env DB_PORT
  echo_env DB_ROOT_USER
  echo_env DB_ROOT_PASSWORD
  echo_env CACHE_HOST
  echo_env CACHE_PORT
  echo_env CACHE_PASSWORD
  echo_env SMTP_HOST
  echo_env SMTP_PORT
  echo_env SMTP_USER
  echo_env SMTP_PASSWORD 21
fi

echo_next "Node Config"
echo_line green
echo_env DO_AUTH_TOKEN 21
echo_env DOCKER_REGISTRY
echo_env ROOT_PASSWORD
echo_env BASICAUTH_USER
echo_env BASICAUTH_PASSWORD
echo_env WEBHOOK 24

echo_next "Swarm Config"
echo_line green
echo_env ROLE
echo_env DROPLET_IMAGE
echo_env REGION
echo_env FS_TYPE
echo_env ROOT_PRIVATE_KEY 20
echo_env ROOT_PUBLIC_KEY 20

# Stop here if inspect only
defined $INSPECT_ONLY && echo && exit

if ask "Continue?"; then  
  echo
else
  echo_stop "Cancelled."  
  exit 1;
fi


# Deletions
defined $REMOVALS && echo_main "Node removals: ${REMOVALS}"
for node in $REMOVALS; do
  if ask "Really DELETE droplet [${node}]?"; then

    echo_next "Removing ${node} from docker swarm..."

    # On primary, demote docker swarm manager to worker
    echo_run $PRIMARY "DEMOTE=1 NODE=${node} /root/platform/swarm/node/docker"

    # On replica, leave docker swarm
    echo_run $node    "LEAVE=1 /root/platform/swarm/node/docker"

    # On primary, remove docker swarm node
    echo_run $PRIMARY "REMOVE=1 NODE=${node} /root/platform/swarm/node/docker"

    # Delete DNS records 
    remove_record "${node}"
    remove_record "*.${node}"

    # # Delete volume
    # remove_volume "${node}"

    # Delete droplet
    remove_droplet "${node}"

  fi
done


# First node provisioned has a primary role
role="primary"
reset_changes

for node_name in $NODES; do
  
  echo_node_header  $node_name $role
  echo_droplet_info $node_name
  [ "$role" = "primary" ] && echo_volume_info $node_name;
  echo_record_info  $node_name

  if has_changes; then 
    if ask "Provision droplet?"; then
      
      # First create/resize the volume that will be attached
      if [ "$role" = "primary" ]; then
        create_or_resize_volume $node_name $role "$NODES"
      fi
      
      # Then create/resize the droplet itself
      create_or_resize_droplet $node_name $role
      
      # Last, ensure the DNS records are pointing to this droplet
      public_ip="$(get_droplet_public_ip $node_name)"
      create_or_update_record "${node_name}" $public_ip
      create_or_update_record "*.${node_name}" $public_ip

      # Create a load balancer for this swarm's primary
      if [ "$ROLE" = "lb" ] && [ "$role" = "primary" ]; then
        has_load_balancer || create_load_balancer
      fi
      
    fi
  fi  
  reset_changes
  
  role="replica"
done
