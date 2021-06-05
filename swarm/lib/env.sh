#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

# ---------------------------------------------------------
# Environment Variables
# ---------------------------------------------------------

if defined $SWARM; then
  if has $SWARMFILE; then
    source $SWARMFILE
  fi
fi

export DO_AUTH_TOKEN="$(env_file DO_AUTH_TOKEN /run/secrets/do_auth_token)"
export ROOT_PASSWORD=$(env_file_default ROOT_PASSWORD /run/secrets/root_password "secret")

export ROOT_PRIVATE_KEY="$(env_file_default ROOT_PRIVATE_KEY /run/secrets/root_private_key)"
if defined $ROOT_PRIVATE_KEY; then
  echo "$ROOT_PRIVATE_KEY" > root_private_key.tmp
  chmod 400 root_private_key.tmp
  export ROOT_PUBLIC_KEY="$(ssh-keygen -y -f root_private_key.tmp) root"
  rm -f root_private_key.tmp
fi

export DROPLET_IMAGE=$(env_file_default DROPLET_IMAGE /etc/droplet_image "ubuntu-20-04-x64")
export REGION=$(env_file_default REGION /etc/region "tor1")
export FS_TYPE=$(env_file_default FS_TYPE /etc/fs_type "ext4")
export WEBHOOK="$(env_file WEBHOOK /etc/webhook)"

export DROPLET_SIZE=$(env_file_default DROPLET_SIZE /dev/null "s-1vcpu-1gb")
export VOLUME_SIZE=$(env_file_default VOLUME_SIZE /dev/null "10")
