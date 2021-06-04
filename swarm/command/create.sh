#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

# Environment Variables
include "lib/env.sh"

if undefined $SWARM; then
  echo
  echo "Usage:  swarm create SWARM [VOLUME_SIZE: $VOLUME_SIZE] [DROPLET_SIZE: $DROPLET_SIZE]"
  echo
  exit 1
fi

defined $NODE || exit 1
defined $DOMAIN || exit 1
defined $SWARMFILE || exit 1

defined $3 && VOLUME_SIZE=$3 || VOLUME_SIZE=10
defined $4 && DROPLET_SIZE=$4 || DROPLET_SIZE="s-1vcpu-1gb"

# Check if swarmfile exists
if has $SWARMFILE; then

  if swarm_exists $SWARM; then
    echo_stop "This swarm already exists and the SWARMFILE is currently in your library: $SWARMFILE"
    exit 1

  else
    include "command/edit.sh"
    include "lib/process.sh"
    include "command/update.sh"
  fi

# Swarmfile doesn't exist
else

  # Check if this droplet's name is being used elsewhere on this Digital Ocean account
  if droplet_reserved $SWARM; then
    echo_stop "The droplet named $SWARM isn't available as a primary node."
    exit 1

  elif swarm_exists $SWARM; then
    echo_stop "This swarm already exists, but you're missing the SWARMFILE: $SWARMFILE"
    exit 1

  # All clear, create the swarmfile
  else

    # Download the template
    rm -rf /tmp/swarmfile
    curl -sL https://github.com/nonfiction/platform/raw/master/swarm/template/swarmfile > /tmp/swarmfile

    # Fill in the blanks
    sed -i "s/__NODE__/${NODE}/g" /tmp/swarmfile
    sed -i "s/__DOMAIN__/${DOMAIN}/g" /tmp/swarmfile

    echo_next "Creating SWARMFILE: ${SWARMFILE}"

    echo_info "Git config info"
    echo "If this swarm is used for development, who is writing these commits?"

    ask_input GIT_USER_NAME
    GIT_USER_NAME=$(ask_env_file_default GIT_USER_NAME /run/secrets/git_user_name)
    sed -i "s/__GIT_USER_NAME__/${GIT_USER_NAME}/g" /tmp/swarmfile
    echo_env GIT_USER_NAME

    ask_input GIT_USER_EMAIL
    GIT_USER_EMAIL=$(ask_env_file_default GIT_USER_EMAIL /run/secrets/git_user_email)
    sed -i "s/__GIT_USER_EMAIL__/${GIT_USER_EMAIL}/g" /tmp/swarmfile
    echo_env GIT_USER_EMAIL

    echo_info "Github account"
    echo "https://github.com/settings/tokens"

    ask_input GITHUB_USER
    GITHUB_USER=$(ask_env_file_default GITHUB_USER /run/secrets/github_user)
    sed -i "s/__GITHUB_USER__/${GITHUB_USER}/g" /tmp/swarmfile
    echo_env GITHUB_USER

    ask_input GITHUB_TOKEN
    GITHUB_TOKEN=$(env_file_ask GITHUB_TOKEN /run/secrets/github_token)
    sed -i "s/__GITHUB_TOKEN__/${GITHUB_TOKEN}/g" /tmp/swarmfile
    echo_env GITHUB_TOKEN

    sed -i "s/__CODE_PASSWORD__/$(generate_password)/g" /tmp/swarmfile 
    sed -i "s/__SUDO_PASSWORD__/$(generate_password)/g" /tmp/swarmfile 

    echo_info "Digital Ocean: personal access token"
    echo "https://cloud.digitalocean.com/account/api/tokens"

    ask_input DO_AUTH_TOKEN
    DO_AUTH_TOKEN=$(env_file_ask DO_AUTH_TOKEN /run/secrets/do_auth_token)
    sed -i "s/__DO_AUTH_TOKEN__/${DO_AUTH_TOKEN}/g" /tmp/swarmfile
    echo_env DO_AUTH_TOKEN

    echo_info "Webhook is called by the swarm manager to signal when nodes are ready"
    echo "https://api.slack.com/messaging/webhooks"

    ask_input WEBHOOK
    WEBHOOK=$(env_file_ask WEBHOOK /run/secrets/webhook)
    sed -i "s|__WEBHOOK__|${WEBHOOK}|g" /tmp/swarmfile
    echo_env WEBHOOK

    echo_info "Digital Ocean: database cluster"
    echo "https://cloud.digitalocean.com/databases"
    ask_input DB_HOST
    DB_HOST=$(env_file_ask DB_HOST /run/secrets/db_host)
    sed -i "s|__DB_HOST__|${DB_HOST}|g" /tmp/swarmfile
    echo_env DB_HOST

    ask_input DB_PASSWORD
    DB_PASSWORD=$(env_file_ask DB_PASSWORD /run/secrets/db_password)
    sed -i "s/__DB_PASSWORD__/${DB_PASSWORD}/g" /tmp/swarmfile
    echo_env DB_PASSWORD

    sed -i "s/__BASICAUTH_PASSWORD__/$(generate_password)/g" /tmp/swarmfile
    sed -i "s/__ROOT_PASSWORD__/$(generate_password)/g" /tmp/swarmfile

    # Generate SSH key at end of file
    echo "export ROOT_PRIVATE_KEY=\"" >> /tmp/swarmfile
    truncate -s-1 /tmp/swarmfile
    generate_key >> /tmp/swarmfile
    truncate -s-1 /tmp/swarmfile 
    echo -n "\"" >> /tmp/swarmfile 
    echo "" >> /tmp/swarmfile 

    # Save from tmp to where it belongs
    mv /tmp/swarmfile $SWARMFILE

    # Edit the swarmfile
    include "command/edit.sh"

    # Re-read env variables from new swarmfile
    unset ROOT_PRIVATE_KEY
    unset ROOT_PUBLIC_KEY
    unset ROOT_PASSWORD
    unset DROPLET_IMAGE
    unset DROPLET_SIZE
    unset VOLUME_SIZE
    unset REGION
    unset FS_TYPE
    unset WEBHOOK
    unset DO_AUTH_TOKEN
    include "lib/env.sh"

    # Create primary
    include "lib/process.sh"

  fi

fi