#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

# Environment Variables
include "command/_env.sh"

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
    include "command/_process.sh"
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
    # curl -sL https://github.com/nonfiction/platform/raw/master/swarm/lib/swarmfile > $SWARMFILE
    cp /root/platform/swarm/lib/swarmfile $SWARMFILE

    # Fill in the blanks
    sed -i "s/__NODE__/${NODE}/g" $SWARMFILE
    sed -i "s/__DOMAIN__/${DOMAIN}/g" $SWARMFILE

    echo -n "GIT_USER_NAME: " 
    GIT_USER_NAME=$(env_file_ask GIT_USER_NAME /run/secrets/git_user_name)
    sed -i "s/__GIT_USER_NAME__/${GIT_USER_NAME}/g" $SWARMFILE
    echo "$GIT_USER_NAME"

    echo -n "GIT_USER_EMAIL: " 
    GIT_USER_EMAIL=$(env_file_ask GIT_USER_EMAIL /run/secrets/git_user_email)
    sed -i "s/__GIT_USER_EMAIL__/${GIT_USER_EMAIL}/g" $SWARMFILE
    echo "$GIT_USER_EMAIL"

    echo -n "GITHUB_USER: " 
    GITHUB_USER=$(env_file_ask GITHUB_USER /run/secrets/github_user)
    sed -i "s/__GITHUB_USER__/${GITHUB_USER}/g" $SWARMFILE
    echo "$GITHUB_USER"

    echo -n "GITHUB_TOKEN: " 
    GITHUB_TOKEN=$(env_file_ask GITHUB_TOKEN /run/secrets/github_token)
    sed -i "s/__GITHUB_TOKEN__/${GITHUB_TOKEN}/g" $SWARMFILE
    echo "$GITHUB_TOKEN"

    sed -i "s/__CODE_PASSWORD__/$(generate_password)/g" $SWARMFILE
    sed -i "s/__SUDO_PASSWORD__/$(generate_password)/g" $SWARMFILE

    echo -n "DO_AUTH_TOKEN: " 
    DO_AUTH_TOKEN=$(env_file_ask DO_AUTH_TOKEN /run/secrets/do_auth_token)
    sed -i "s/__DO_AUTH_TOKEN__/${DO_AUTH_TOKEN}/g" $SWARMFILE
    echo "$DO_AUTH_TOKEN"

    echo -n "WEBHOOK: " 
    WEBHOOK=$(env_file_ask WEBHOOK /run/secrets/webhook)
    sed -i "s|__WEBHOOK__|${WEBHOOK}|g" $SWARMFILE
    echo "$WEBHOOK"

    echo -n "DB_HOST: " 
    DB_HOST=$(env_file_ask DB_HOST /run/secrets/db_host)
    sed -i "s/__DB_HOST__/${DB_HOST}/g" $SWARMFILE
    echo "$DB_HOST"

    echo -n "DB_PASSWORD: " 
    DB_PASSWORD=$(env_file_ask DB_PASSWORD /run/secrets/db_password)
    sed -i "s/__DB_PASSWORD__/${DB_PASSWORD}/g" $SWARMFILE
    echo "$DB_PASSWORD"

    sed -i "s/__BASICAUTH_PASSWORD__/$(generate_password)/g" $SWARMFILE
    sed -i "s/__ROOT_PASSWORD__/$(generate_password)/g" $SWARMFILE

    # Generate SSH key at end of file
    echo "export ROOT_PRIVATE_KEY=\"" >> $SWARMFILE
    truncate -s-1 $SWARMFILE
    generate_key >> $SWARMFILE
    truncate -s-1 $SWARMFILE
    echo -n "\"" >> $SWARMFILE
    echo "" >> $SWARMFILE

    # Edit the swarmfile
    include "command/edit.sh"

    # Create primary
    include "command/_process.sh"

  fi

fi
