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


export DROPLET_IMAGE=$(env_file_default DROPLET_IMAGE /usr/local/env/DROPLET_IMAGE "ubuntu-20-04-x64")
export REGION=$(env_file_default REGION /usr/local/env/REGION "tor1")
export FS_TYPE=$(env_file_default FS_TYPE /usr/local/env/FS_TYPE "ext4")

export DO_AUTH_TOKEN="$(env_file DO_AUTH_TOKEN /usr/local/env/DO_AUTH_TOKEN)"
export ROOT_PASSWORD=$(env_file_default ROOT_PASSWORD /usr/local/env/ROOT_PASSWORD "secret")

export ROOT_PRIVATE_KEY="$(env_file_default ROOT_PRIVATE_KEY /usr/local/env/ROOT_PRIVATE_KEY)"
if defined $ROOT_PRIVATE_KEY; then
  echo "$ROOT_PRIVATE_KEY" | base64 -d > root_private_key.tmp
  chmod 400 root_private_key.tmp
  export ROOT_PUBLIC_KEY="$(ssh-keygen -y -f root_private_key.tmp) root"
  rm -f root_private_key.tmp
fi

export WEBHOOK="$(env_file WEBHOOK /etc/webhook)"

export GIT_USER_NAME=$(env_file GIT_USER_NAME /usr/local/env/GIT_USER_NAME)
export GIT_USER_EMAIL=$(env_file GIT_USER_EMAIL /usr/local/env/GIT_USER_EMAIL)
export GITHUB_USER=$(env_file GITHUB_USER /usr/local/env/GITHUB_USER)
export GITHUB_TOKEN=$(env_file GITHUB_TOKEN /usr/local/env/GITHUB_TOKEN)

export CODE_PASSWORD=$(env_file CODE_PASSWORD /usr/local/env/CODE_PASSWORD)
export SUDO_PASSWORD=$(env_file SUDO_PASSWORD /usr/local/env/SUDO_PASSWORD)

export DB_HOST=$(env_file DB_HOST /usr/local/env/DB_HOST)
export DB_PORT=$(env_file_default DB_PORT /usr/local/env/DB_PORT "25060")
export DB_USER=$(env_file_default DB_USER /usr/local/env/DB_USER "doadmin")
export DB_PASSWORD=$(env_file DB_PASSWORD /usr/local/env/DB_PASSWORD)

export BASICAUTH_USER=$(env_file_default BASICAUTH_USER /usr/local/env/BASICAUTH_USER "nonfiction")
export BASICAUTH_PASSWORD=$(env_file_default BASICAUTH_PASSWORD /usr/local/env/BASICAUTH_PASSWORD "secret")

export DROPLET_SIZE=$(env_file_default DROPLET_SIZE /dev/null "s-1vcpu-1gb")
export VOLUME_SIZE=$(env_file_default VOLUME_SIZE /dev/null "10")
