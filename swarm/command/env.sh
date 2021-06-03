#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

# ---------------------------------------------------------
# Environment Variables
# ---------------------------------------------------------

if has $SWARMFILE; then
  source $SWARMFILE
fi

# ROOT_PRIVATE_KEY="$(env_or_file ROOT_PRIVATE_KEY ./root_private_key /run/secrets/root_private_key)"
export ROOT_PRIVATE_KEY="$(env_or_file ROOT_PRIVATE_KEY /run/secrets/root_private_key)"
if defined $ROOT_PRIVATE_KEY; then
  echo "$ROOT_PRIVATE_KEY" > root_private_key.tmp
  chmod 400 root_private_key.tmp
  export ROOT_PUBLIC_KEY="$(ssh-keygen -y -f root_private_key.tmp) root"
  rm -f root_private_key.tmp
fi
export ROOT_PASSWORD=$(env_or_file ROOT_PASSWORD /run/secrets/root_password)
undefined $DROPLET_IMAGE && export DROPLET_IMAGE="ubuntu-20-04-x64"
undefined $DROPLET_SIZE && export DROPLET_SIZE="s-1vcpu-1gb"
undefined $VOLUME_SIZE && export VOLUME_SIZE="10"
undefined $REGION && export REGION="tor1"
undefined $FS_TYPE && export FS_TYPE="ext4"
export WEBHOOK="$(env_or_file WEBHOOK /run/secrets/webhook)"
