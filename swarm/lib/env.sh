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

# ROOT_PRIVATE_KEY="$(env_or_file ROOT_PRIVATE_KEY ./root_private_key /run/secrets/root_private_key)"
# export ROOT_PRIVATE_KEY="$(env_or_file ROOT_PRIVATE_KEY /run/secrets/root_private_key)"
# if defined $ROOT_PRIVATE_KEY; then
#   echo "$ROOT_PRIVATE_KEY" > root_private_key.tmp
#   chmod 400 root_private_key.tmp
#   export ROOT_PUBLIC_KEY="$(ssh-keygen -y -f root_private_key.tmp) root"
#   rm -f root_private_key.tmp
# fi
# export ROOT_PASSWORD=$(env_or_file ROOT_PASSWORD /run/secrets/root_password)
# undefined $DROPLET_IMAGE && export DROPLET_IMAGE="ubuntu-20-04-x64"
# undefined $DROPLET_SIZE && export DROPLET_SIZE="s-1vcpu-1gb"
# undefined $VOLUME_SIZE && export VOLUME_SIZE="10"
# undefined $REGION && export REGION="tor1"
# undefined $FS_TYPE && export FS_TYPE="ext4"
# export WEBHOOK="$(env_or_file WEBHOOK /run/secrets/webhook)"


export ROOT_PRIVATE_KEY="$(env_file_default ROOT_PRIVATE_KEY /run/secrets/root_private_key)"
if defined $ROOT_PRIVATE_KEY; then
  echo "$ROOT_PRIVATE_KEY" > root_private_key.tmp
  chmod 400 root_private_key.tmp
  export ROOT_PUBLIC_KEY="$(ssh-keygen -y -f root_private_key.tmp) root"
  rm -f root_private_key.tmp
fi
export ROOT_PASSWORD=$(env_file_default ROOT_PASSWORD /run/secrets/root_password "secret")
export DROPLET_IMAGE=$(env_file_default DROPLET_IMAGE /run/secrets/droplet_image "ubuntu-20-04-x64")
export DROPLET_SIZE=$(env_file_default DROPLET_SIZE /run/secrets/droplet_size "s-1vcpu-1gb")
export VOLUME_SIZE=$(env_file_default VOLUME_SIZE /run/secrets/volume_size "10")
export REGION=$(env_file_default REGION /run/secrets/region "tor1")
export FS_TYPE=$(env_file_default FS_TYPE /run/secrets/fs_type "ext4")
export WEBHOOK="$(env_or_file WEBHOOK /run/secrets/webhook)"
export DO_AUTH_TOKEN="$(env_or_file DO_AUTH_TOKEN /run/secrets/do_auth_token)"
