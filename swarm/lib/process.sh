#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

defined $SWARM
defined $NODE
defined $DOMAIN

defined $PRIMARY || PRIMARY=$(get_swarm_primary)
defined $REPLICAS || REPLICAS=$(get_swarm_replicas)
defined $NODES || NODES="$(echo "${PRIMARY} ${REPLICAS}" | xargs)"

# Environment Variables
include "lib/env.sh"

# Ensure new droplets have a volume size no smaller than primary's volume 
# This is because a replicated volume will only be as largest as it's smallest node
if has_droplet $PRIMARY; then
  primary_volume_size=$(get_volume_size $PRIMARY)
  [ "$VOLUME_SIZE" -lt "$primary_volume_size" ] && VOLUME_SIZE=$primary_volume_size

# If primary doesn't exist yet, count that as an addition
else
  ADDITIONS="$(echo "$PRIMARY $ADDITIONS" | args)"
fi



# # Display the main header
# echo_line blue
# echo " $(echo_color black/on_blue "[${SWARM}]") $(echo_color blue "SWARM MANAGER")"
# echo_line blue
#
# Count the number of nodes in this swarm
count=$((1 + $(echo $REPLICAS | wc -w)))
[ "$count" = "1" ] && count="" || count="[x${count}]"
echo_next "${SWARM} ${count}"
echo_line green
echo_env PRIMARY
defined $REPLICAS  && echo_env REPLICAS
defined $PROMOTED  && echo_env PROMOTED
defined $DEMOTED   && echo_env DEMOTED
defined $REMOVALS  && echo_env REMOVALS
defined $ADDITIONS && echo_env ADDITIONS
echo_env VOLUME_SIZE
echo_env DROPLET_SIZE


# ---------------------------------------------------------
# Environment Variables
# ---------------------------------------------------------
# include "command/env.sh"
# source $SWARMFILE
#
# # ROOT_PRIVATE_KEY="$(env_or_file ROOT_PRIVATE_KEY ./root_private_key /run/secrets/root_private_key)"
# ROOT_PRIVATE_KEY="$(env_or_file ROOT_PRIVATE_KEY /run/secrets/root_private_key)"
# if defined $ROOT_PRIVATE_KEY; then
#   echo "$ROOT_PRIVATE_KEY" > root_private_key.tmp
#   chmod 400 root_private_key.tmp
#   ROOT_PUBLIC_KEY="$(ssh-keygen -y -f root_private_key.tmp) root"
#   rm -f root_private_key.tmp
# fi
# ROOT_PASSWORD=$(env_or_file ROOT_PASSWORD /run/secrets/root_password)
# undefined $DROPLET_IMAGE && DROPLET_IMAGE="ubuntu-20-04-x64"
# undefined $DROPLET_SIZE && DROPLET_SIZE="s-1vcpu-1gb"
# undefined $VOLUME_SIZE && VOLUME_SIZE="10"
# undefined $REGION && REGION="tor1"
# undefined $FS_TYPE && FS_TYPE="ext4"
# WEBHOOK="$(env_or_file WEBHOOK /run/secrets/webhook)"



echo_next "Workspace Config"
echo_line green
echo_env GIT_USER_NAME
echo_env GIT_USER_EMAIL
echo_env GITHUB_USER
echo_env GITHUB_TOKEN
echo_env CODE_PASSWORD
echo_env SUDO_PASSWORD
echo_env DB_USER
echo_env DB_PASSWORD
echo_env DB_HOST
echo_env DB_PORT

echo_next "Node Config"
echo_line green
echo_env DO_AUTH_TOKEN 21
echo_env ROOT_PASSWORD
echo_env BASICAUTH_USER
echo_env BASICAUTH_PASSWORD
echo_env WEBHOOK 24

echo_next "Swarm Config"
echo_line green
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


# Promotion/demotion
defined $DEMOTED && echo_main "New Primary: ${DEMOTED} => ${PROMOTED}"
if defined $DEMOTED; then

  if droplets_ready "$NODES"; then
    echo_next "...ready!"
  else
    echo_stop "Not ready for reassignment!"
    exit
  fi

  # On primary, promote docker swarm manager to worker
  echo_run $DEMOTED "PROMOTE=1 NODE=${PROMOTED} /root/platform/swarm/node/docker"
  echo_info "Demoted $DEMOTED to worker in swarm"

  # On demoted, demote docker swarm manager to worker
  echo_run $PROMOTED "DEMOTE=1 NODE=${DEMOTED} /root/platform/swarm/node/docker"
  echo_info "Promoted $PROMOTED to manager in swarm"

  # Role tags for this swarm
  primary_tag=$(primary_tag)
  replica_tag=$(replica_tag)

  # Change the demoted node from primary to replica
  droplet_untag $DEMOTED $primary_tag
  droplet_tag $DEMOTED $replica_tag
  echo_info "Tagged $DEMOTED as ${replica_tag}"

  # Change the promoted node from replica to primary
  droplet_untag $PROMOTED $replica_tag
  droplet_tag $PROMOTED $primary_tag
  echo_info "Tagged $PROMOTED as ${primary_tag}"

  # Done
  echo
  echo_line green
  echo_color black/on_green " COMPLETE! "
  echo_line green

  exit

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

    echo_next "Removing ${node} from gluster volume..."

    # On primary, remove brick and peer from gluster volume
    echo_run $PRIMARY "REMOVE=1 NODE=${node} /root/platform/swarm/node/gluster"

    # Delete DNS records 
    remove_record "${node}"
    remove_record "*.${node}"

    # Delete volume
    remove_volume "${node}"

    # Delete droplet
    remove_droplet "${node}"

  fi
done


# First node processed has a primary role
role="primary"
reset_changes

for node_name in $NODES; do
  
  echo_node_header  $node_name $role
  echo_droplet_info $node_name
  echo_volume_info  $node_name
  echo_record_info  $node_name

  if has_changes; then 
    if ask "Process droplet?"; then
      
      # First create/resize the volume that will be attached
      create_or_resize_volume $node_name $role
      
      # Then create/resize the droplet itself
      create_or_resize_droplet $node_name $role
      
      # Last, ensure the DNS records are pointing to this droplet
      public_ip="$(get_droplet_public_ip $node_name)"
      create_or_update_record "${node_name}" $public_ip
      create_or_update_record "*.${node_name}" $public_ip
      
    fi
  fi  
  reset_changes
  
  role="replica"
done
