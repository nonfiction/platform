#!/bin/bash

# Bash helper functions
has include && include "lib/helpers.sh"

# ---------------------------------------------------------
# Environment Variables
# ---------------------------------------------------------

if defined $SWARM; then
  if has $SWARMFILE; then
    source $SWARMFILE
  fi
fi

export ROLE="$(env ROLE)"

export DROPLET_IMAGE=$(env DROPLET_IMAGE "ubuntu-20-04-x64")
export REGION=$(env REGION "tor1")
export FS_TYPE=$(env FS_TYPE "ext4")

export DO_AUTH_TOKEN="$(env DO_AUTH_TOKEN)"
export ROOT_PASSWORD=$(env ROOT_PASSWORD "secret")

export ROOT_PRIVATE_KEY="$(env ROOT_PRIVATE_KEY)"
if defined $ROOT_PRIVATE_KEY; then
  echo "$ROOT_PRIVATE_KEY" | base64 -d > /tmp/root_private_key
  chmod 400 /tmp/root_private_key
  export ROOT_PUBLIC_KEY="$(ssh-keygen -y -f /tmp/root_private_key) root"
  rm -f /tmp/root_private_key
fi

export WEBHOOK="$(env WEBHOOK)"

export GIT_USER_NAME=$(env GIT_USER_NAME)
export GIT_USER_EMAIL=$(env GIT_USER_EMAIL)
export GITHUB_USER=$(env GITHUB_USER)
export GITHUB_TOKEN=$(env GITHUB_TOKEN)

export CODE_PASSWORD=$(env CODE_PASSWORD)
export SUDO_PASSWORD=$(env SUDO_PASSWORD)

export DOCKER_REGISTRY=$(env DOCKER_REGISTRY registry.digitalocean.com/nonfiction)

export DB_HOST=$(env DB_HOST)
export DB_PORT=$(env DB_PORT "25060")
export DB_ROOT_USER=$(env DB_ROOT_USER "doadmin")
export DB_ROOT_PASSWORD=$(env DB_ROOT_PASSWORD)

export SMTP_HOST=$(env SMTP_HOST "smtp.sendgrid.net")
export SMTP_PORT=$(env SMTP_PORT "587")
export SMTP_USER=$(env SMTP_USER "apikey")
export SMTP_PASSWORD=$(env SMTP_PASSWORD)

export BASICAUTH_USER=$(env BASICAUTH_USER "nonfiction")
export BASICAUTH_PASSWORD=$(env BASICAUTH_PASSWORD "secret")

export DROPLET_SIZE=$(env DROPLET_SIZE "s-1vcpu-1gb")
export VOLUME_SIZE=$(env VOLUME_SIZE "10")
