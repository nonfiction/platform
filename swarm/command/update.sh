#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

if undefined $SWARM; then
  echo
  echo "Usage:  swarm update SWARM"
  echo
  exit 1
fi

# Check if swarmfile exists
if hasnt $SWARMFILE; then
  echo_stop "This SWARMFILE doesn't exist in your library: $SWARMFILE"
  exit 1
fi

# ---------------------------------------------------------
# Environment Variables
# ---------------------------------------------------------
include "lib/env.sh"

defined $PRIMARY || PRIMARY=$(get_swarm_primary)
defined $REPLICAS || REPLICAS=$(get_swarm_replicas)
defined $NODES || NODES="$(echo "${PRIMARY} ${REPLICAS}" | xargs)"


# ---------------------------------------------------------
# Verify all nodes are ready
# ---------------------------------------------------------
if droplets_ready "$NODES"; then
  echo_next "...ready!"
else
  echo_stop "Not ready for configuration! Newly created droplets require 5-10 minutes."
  exit
fi

# Count the nodes
sum=$(echo $NODES | wc -w)

# ---------------------------------------------------------
# System configuration for each node
# ---------------------------------------------------------
echo_main "1. Node Config..."
count=1

# Build hosts file
hosts="127.0.0.1 localhost"
for node in $NODES; do
  ip="$(get_droplet_private_ip $node)"
  hosts="${hosts}\n${ip} ${node}"
done

# Loop all nodes in swarm
for node in $NODES; do
  
  # Current node heading
  echo_node_counter $count $sum $node
  ((count++))

  # Pull updates from git
  run $node "/root/platform/swarm/node/update"

  # Prepare environment variables for run command
  env=""
  env="${env} NODE=\"$node\""
  env="${env} DOMAIN=\"$DOMAIN\""
  env="${env} FS_TYPE=\"$FS_TYPE\""
  env="${env} HOSTS_FILE=\"$hosts\""
  env="${env} WEBHOOK=\"$WEBHOOK\""
  env="${env} ROOT_PASSWORD=\"$ROOT_PASSWORD\""
  env="${env} ROOT_PUBLIC_KEY=\"$ROOT_PUBLIC_KEY\""

  # Run script on node
  run $node "${env} /root/platform/swarm/node/node"

done  
  

# ---------------------------------------------------------
# Create Docker Swarm and join workers
# ---------------------------------------------------------
echo_main "2. Docker Config..."
count=1

# Loop all nodes in swarm
for node in $NODES; do

  # Current node heading
  echo_node_counter $count $sum $node
  ((count++))

  # Set join token to "primary" if not replica
  if [ "$node" = "$PRIMARY" ]; then
    join_token="primary"

  # Else, get join token from primary node
  else
    join_token="$(run $PRIMARY "cat /etc/docker-join-token")"
  fi
  
  # Prepare environment variables for run command
  env="JOIN=1"
  env="${env} NODE=\"$node\""
  env="${env} PRIVATE_IP=\"$(get_droplet_private_ip $node)\""
  env="${env} JOIN_TOKEN=\"$join_token\""

  # Run script on node
  run $node "${env} /root/platform/swarm/node/docker"

done


# ---------------------------------------------------------
# Create Gluster Volume
# ---------------------------------------------------------
echo_main "3. Gluster Config..."
count=1

# Loop all nodes in swarm
for node in $NODES; do

  # Current node heading
  echo_node_counter $count $sum $node
  ((count++))

  # Prepare environment variables for run command
  env="JOIN=1"
  env="${env} NODE=\"$node\""
  env="${env} NODES=\"$NODES\""
  env="${env} PRIMARY=\"$PRIMARY\""

  # Run script on node
  run $node "${env} /root/platform/swarm/node/gluster"

done


# ---------------------------------------------------------
# Deploy Swarm
# ---------------------------------------------------------
echo_main "4. Deploy Swarm..."
run $PRIMARY "cd /root/platform && ls -lah"


# ---------------------------------------------------------
# Finish
# ---------------------------------------------------------
echo
echo_line green
echo_color black/on_green " COMPLETE! "
echo_line green

exit
