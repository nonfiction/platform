#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"
verify_esh

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

if undefined $SWARM; then
  echo
  echo "Usage:  $CMD_NAME deploy SWARM"
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

# Skip this if provision is called from "swarm size"
if undefined $RESIZE; then

  # Get primary and its size 
  PRIMARY=$(get_swarm_primary)
  VOLUME_SIZE=$(get_volume_size $PRIMARY)
  DROPLET_SIZE=$(get_droplet_size $PRIMARY)

  # Environment Variables
  include "lib/env.sh"

fi

REPLICAS=$(get_swarm_replicas)
NODES="$(echo "${PRIMARY} ${REPLICAS}" | xargs)"

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
step=0
((step++))
echo_main "$step. Node Config..."
count=1

# Build hosts file
hosts="127.0.0.1 localhost"
for node in $NODES; do
  ip="$(get_droplet_private_ip $node)"
  [ "$node" = "$PRIMARY" ] && node="${node} primary"
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
  env="${env} PRIMARY_IP=\"$(get_droplet_private_ip $PRIMARY)\""
  env="${env} HOSTS_FILE=\"$hosts\""
  env="${env} DO_AUTH_TOKEN=\"$DO_AUTH_TOKEN\""
  env="${env} DOCKER_REGISTRY=\"$DOCKER_REGISTRY\""
  env="${env} WEBHOOK=\"$WEBHOOK\""

  env="${env} BASICAUTH_USER=\"$BASICAUTH_USER\""
  env="${env} BASICAUTH_PASSWORD=\"$BASICAUTH_PASSWORD\""

  env="${env} GIT_USER_NAME=\"$GIT_USER_NAME\""
  env="${env} GIT_USER_EMAIL=\"$GIT_USER_EMAIL\""
  env="${env} GITHUB_USER=\"$GITHUB_USER\""
  env="${env} GITHUB_TOKEN=\"$GITHUB_TOKEN\""

  env="${env} CODE_PASSWORD=\"$CODE_PASSWORD\""
  env="${env} SUDO_PASSWORD=\"$SUDO_PASSWORD\""
  env="${env} ROOT_PASSWORD=\"$ROOT_PASSWORD\""
  env="${env} ROOT_PUBLIC_KEY=\"$ROOT_PUBLIC_KEY\""

  env="${env} DB_HOST=\"$DB_HOST\""
  env="${env} DB_PORT=\"$DB_PORT\""
  env="${env} DB_ROOT_USER=\"$DB_ROOT_USER\""
  env="${env} DB_ROOT_PASSWORD=\"$DB_ROOT_PASSWORD\""

  env="${env} SMTP_HOST=\"$SMTP_HOST\""
  env="${env} SMTP_PORT=\"$SMTP_PORT\""
  env="${env} SMTP_USER=\"$SMTP_USER\""
  env="${env} SMTP_PASSWORD=\"$SMTP_PASSWORD\""

  env="${env} ROOT_PRIVATE_KEY=\"$ROOT_PRIVATE_KEY\""
  env="${env} DROPLET_IMAGE=\"$DROPLET_IMAGE\""
  env="${env} REGION=\"$REGION\""
  env="${env} FS_TYPE=\"$FS_TYPE\""

  env="${env} ROLE=\"$ROLE\""
  env="${env} SWARMFILE_CONTENTS=\"$(cat $SWARMFILE | base64 | tr -d '\n')\""

  # Run script on node
  run $node "${env} /root/platform/swarm/node/node"

done  
  

# ---------------------------------------------------------
# Create Docker Swarm and join workers
# ---------------------------------------------------------
((step++))
echo_main "$step. Docker Config..."
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
    join_token="$(run $PRIMARY "cat /usr/local/env/DOCKER_JOIN_TOKEN")"
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
((step++))
echo_main "$step. Gluster Config..."
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
# Point DNS to load balancer if applicable
# ---------------------------------------------------------
if [ "$ROLE" = "lb" ]; then
  ((step++))
  echo_main "$step. Load Balancer Config..."

    lb_node="$(load_balancer_node)"
    lb_ip="$(get_load_balancer_ip)"

    if defined "$lb_node" && defined "$lb_ip"; then
      create_or_update_record $lb_node $lb_ip
      create_or_update_record "*.$lb_node" $lb_ip
    fi

fi


# ---------------------------------------------------------
# Deploy Swarm
# ---------------------------------------------------------
((step++))
echo_main "$step. Deploy Swarm..."

if [ "$ROLE" = "dev" ]; then
  run $PRIMARY "cd /root/platform && make workspace"

elif [ "$ROLE" = "lb" ]; then
  run $PRIMARY "cd /root/platform && make caddy"

else
  run $PRIMARY "cd /root/platform && make traefik"
fi


# ---------------------------------------------------------
# Finish
# ---------------------------------------------------------
echo
echo_line green
echo_color black/on_green " COMPLETE! "
echo_line green

exit
