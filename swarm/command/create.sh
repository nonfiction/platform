#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"
verify_esh

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

# Override VOLUME_SIZE or DROPLET_SIZE
for arg in $ARGS; do
  if [[ $arg =~ ^[0-9]+$ ]]; then 
    export VOLUME_SIZE=$arg
  else
    export DROPLET_SIZE=$arg
  fi
done

# Check if swarmfile exists
if has $SWARMFILE; then

  if swarm_exists $SWARM; then
    echo_stop "This swarm already exists and the SWARMFILE is currently in your library: $SWARMFILE"
    exit 1

  else
    include "command/edit.sh"
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

    # Fill in the blanks
    # sed -i "s|__NODE__|${NODE}|g" /tmp/swarmfile
    # sed -i "s|__DOMAIN__|${DOMAIN}|g" /tmp/swarmfile

    echo_next "Creating SWARMFILE: ${SWARMFILE}"

    echo_main_alt "Droplet Details"

    ask_input DROPLET_IMAGE
    DROPLET_IMAGE=$(ask_env DROPLET_IMAGE "ubuntu-20-04-x64")
    # sed -i "s|__DROPLET_IMAGE__|${DROPLET_IMAGE}|g" /tmp/swarmfile
    echo_env DROPLET_IMAGE

    ask_input REGION
    REGION=$(ask_env REGION "tor1")
    # sed -i "s|__REGION__|${REGION}|g" /tmp/swarmfile
    echo_env REGION
    
    ask_input FS_TYPE
    FS_TYPE=$(ask_env FS_TYPE "ext4")
    # sed -i "s|__FS_TYPE__|${FS_TYPE}|g" /tmp/swarmfile
    echo_env FS_TYPE

    # Generate SSH key (base64-encoded)
    ROOT_PRIVATE_KEY=$(generate_key)
    ROOT_PASSWORD=$(generate_password)
    # sed -i "s|__ROOT_PRIVATE_KEY__|$(generate_key)|g" /tmp/swarmfile
    # sed -i "s|__ROOT_PASSWORD__|$(generate_password)|g" /tmp/swarmfile


    echo_main_alt "Digital Ocean: personal access token"
    echo "https://cloud.digitalocean.com/account/api/tokens"

    ask_input DO_AUTH_TOKEN
    DO_AUTH_TOKEN=$(ask_env DO_AUTH_TOKEN)
    # sed -i "s|__DO_AUTH_TOKEN__|${DO_AUTH_TOKEN}|g" /tmp/swarmfile
    echo_env DO_AUTH_TOKEN


    echo_main_alt "Webhook is called by the swarm manager to signal when nodes are ready"
    echo "https://api.slack.com/messaging/webhooks"

    ask_input WEBHOOK
    WEBHOOK=$(ask_env WEBHOOK)
    # sed -i "s|__WEBHOOK__|${WEBHOOK}|g" /tmp/swarmfile
    echo_env WEBHOOK


    echo_main_alt "Git config info"
    echo "If this swarm is used for development, who is writing these commits?"

    ask_input GIT_USER_NAME
    GIT_USER_NAME=$(ask_env GIT_USER_NAME)
    # sed -i "s|__GIT_USER_NAME__|${GIT_USER_NAME}|g" /tmp/swarmfile
    echo_env GIT_USER_NAME

    ask_input GIT_USER_EMAIL
    GIT_USER_EMAIL=$(ask_env GIT_USER_EMAIL)
    # sed -i "s|__GIT_USER_EMAIL__|${GIT_USER_EMAIL}|g" /tmp/swarmfile
    echo_env GIT_USER_EMAIL

    echo_main_alt "Github account"
    echo "https://github.com/settings/tokens"

    ask_input GITHUB_USER
    GITHUB_USER=$(ask_env GITHUB_USER)
    # sed -i "s|__GITHUB_USER__|${GITHUB_USER}|g" /tmp/swarmfile
    echo_env GITHUB_USER

    ask_input GITHUB_TOKEN
    GITHUB_TOKEN=$(ask_env GITHUB_TOKEN)
    # sed -i "s|__GITHUB_TOKEN__|${GITHUB_TOKEN}|g" /tmp/swarmfile
    echo_env GITHUB_TOKEN


    echo_main_alt "VS Code password"
    echo "This really ought to be a complicated password"

    ask_input CODE_PASSWORD
    CODE_PASSWORD=$(ask_env CODE_PASSWORD $(generate_password))
    # sed -i "s|__CODE_PASSWORD__|${CODE_PASSWORD}|g" /tmp/swarmfile 


    echo_main_alt "Sudo password"
    echo "Choose something you don't mind typing regularily"

    ask_input SUDO_PASSWORD
    SUDO_PASSWORD=$(ask_env SUDO_PASSWORD $(generate_password))
    # sed -i "s|__SUDO_PASSWORD__|${SUDO_PASSWORD}|g" /tmp/swarmfile 


    echo_main_alt "Digital Ocean: database cluster"
    echo "https://cloud.digitalocean.com/databases"

    ask_input DB_HOST
    DB_HOST=$(ask_env DB_HOST)
    # sed -i "s|__DB_HOST__|${DB_HOST}|g" /tmp/swarmfile
    echo_env DB_HOST

    ask_input DB_PORT
    DB_PORT=$(ask_env DB_PORT "25060")
    # sed -i "s|__DB_PORT__|${DB_PORT}|g" /tmp/swarmfile
    echo_env DB_PORT

    ask_input DB_USER
    DB_USER=$(ask_env DB_USER "doadmin")
    # sed -i "s|__DB_USER__|${DB_USER}|g" /tmp/swarmfile
    echo_env DB_USER

    ask_input DB_PASSWORD
    DB_PASSWORD=$(ask_env DB_PASSWORD)
    # sed -i "s|__DB_PASSWORD__|${DB_PASSWORD}|g" /tmp/swarmfile
    echo_env DB_PASSWORD

    echo_main_alt "BasicAuth login"
    echo "This may need to be shared with clients occasionally"

    ask_input BASICAUTH_USER
    BASICAUTH_USER=$(ask_env BASICAUTH_USER "nonfiction")
    # sed -i "s|__BASICAUTH_USER__|${BASICAUTH_USER}|g" /tmp/swarmfile
    echo_env BASICAUTH_USER

    ask_input BASICAUTH_PASSWORD
    BASICAUTH_PASSWORD=$(ask_env BASICAUTH_PASSWORD $(generate_password))
    # sed -i "s|__BASICAUTH_PASSWORD__|${BASICAUTH_PASSWORD}|g" /tmp/swarmfile
    echo_env BASICAUTH_PASSWORD


    # Confirm
    if ask "Save?"; then  

      # Download the template
      rm -rf /tmp/swarmfile.esh
      curl -sL https://github.com/nonfiction/platform/raw/main/swarm/template/swarmfile.esh > /tmp/swarmfile.esh

      # Generate the swarmfile and save to where it belongs
      esh /tmp/swarmfile.esh > $SWARMFILE
      rm -f /tmp/swarmfile

    else
      echo_stop "Cancelled."  
      exit 1;
    fi

    echo_info "...done!"
    echo_next "swarm edit $SWARM - edit the newly created swarm"
    echo_next "swarm provision $SWARM - provision the newly created swarm"

  fi

fi
