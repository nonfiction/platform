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

    echo_next "Creating SWARMFILE: ${SWARMFILE}"
    export NODE
    export DOMAIN

    echo_main_alt "Droplet Details"

    ask_input DROPLET_IMAGE
    export DROPLET_IMAGE=$(ask_env DROPLET_IMAGE "ubuntu-20-04-x64")
    echo_env DROPLET_IMAGE

    ask_input REGION
    export REGION=$(ask_env REGION "tor1")
    echo_env REGION
    
    ask_input FS_TYPE
    export FS_TYPE=$(ask_env FS_TYPE "ext4")
    echo_env FS_TYPE

    # Generate SSH key (base64-encoded)
    export ROOT_PRIVATE_KEY=$(generate_key)
    export ROOT_PASSWORD=$(generate_password)


    echo_main_alt "Digital Ocean: personal access token"
    echo "https://cloud.digitalocean.com/account/api/tokens"

    ask_input DO_AUTH_TOKEN
    export DO_AUTH_TOKEN=$(ask_env DO_AUTH_TOKEN)
    echo_env DO_AUTH_TOKEN

    ask_input DOCKER_REGISTRY
    export DOCKER_REGISTRY=$(ask_env DOCKER_REGISTRY registry.digitalocean.com/nonfiction)
    echo_env DOCKER_REGISTRY


    echo_main_alt "Webhook is called by the swarm manager to signal when nodes are ready"
    echo "https://api.slack.com/messaging/webhooks"

    ask_input WEBHOOK
    export WEBHOOK=$(ask_env WEBHOOK)
    echo_env WEBHOOK


    echo_main_alt "Git config info"
    echo "If this swarm is used for development, who is writing these commits?"

    ask_input GIT_USER_NAME
    export GIT_USER_NAME=$(ask_env GIT_USER_NAME)
    echo_env GIT_USER_NAME

    ask_input GIT_USER_EMAIL
    export GIT_USER_EMAIL=$(ask_env GIT_USER_EMAIL)
    echo_env GIT_USER_EMAIL

    echo_main_alt "Github account"
    echo "https://github.com/settings/tokens"

    ask_input GITHUB_USER
    export GITHUB_USER=$(ask_env GITHUB_USER)
    echo_env GITHUB_USER

    ask_input GITHUB_TOKEN
    export GITHUB_TOKEN=$(ask_env GITHUB_TOKEN)
    echo_env GITHUB_TOKEN


    echo_main_alt "VS Code password"
    echo "This really ought to be a complicated password"

    ask_input CODE_PASSWORD
    export CODE_PASSWORD=$(ask_env CODE_PASSWORD $(generate_password))


    echo_main_alt "Sudo password"
    echo "Choose something you don't mind typing regularily"

    ask_input SUDO_PASSWORD
    export SUDO_PASSWORD=$(ask_env SUDO_PASSWORD $(generate_password))


    echo_main_alt "Digital Ocean: database cluster"
    echo "https://cloud.digitalocean.com/databases"

    ask_input DB_HOST
    export DB_HOST=$(ask_env DB_HOST)
    echo_env DB_HOST

    ask_input DB_PORT
    export DB_PORT=$(ask_env DB_PORT "25060")
    echo_env DB_PORT

    ask_input DB_ROOT_USER
    export DB_ROOT_USER=$(ask_env DB_ROOT_USER "doadmin")
    echo_env DB_ROOT_USER

    ask_input DB_ROOT_PASSWORD
    export DB_ROOT_PASSWORD=$(ask_env DB_ROOT_PASSWORD)
    echo_env DB_ROOT_PASSWORD

    echo_main_alt "BasicAuth login"
    echo "This may need to be shared with clients occasionally"

    ask_input BASICAUTH_USER
    export BASICAUTH_USER=$(ask_env BASICAUTH_USER "nonfiction")
    echo_env BASICAUTH_USER

    ask_input BASICAUTH_PASSWORD
    export BASICAUTH_PASSWORD=$(ask_env BASICAUTH_PASSWORD $(generate_password))
    echo_env BASICAUTH_PASSWORD


    # Confirm
    if ask "Save?"; then  

      # Download the template
      curl -sL https://github.com/nonfiction/platform/raw/main/swarm/template/swarmfile.esh > /tmp/swarmfile.esh

      # Generate the swarmfile and save to where it belongs
      esh /tmp/swarmfile.esh > $SWARMFILE
      rm -rf /tmp/swarmfile.esh

      # Add created swarm as docker context
      if has docker; then
        echo_next "Creating DOCKER CONTEXT: ${SWARM}"
        echo_run "docker context create $NODE --default-stack-orchestrator=swarm --docker host=ssh://root@${SWARM}"
      fi

    else
      echo_stop "Cancelled."  
      exit 1;
    fi

    echo_info "...done!"
    echo_next "swarm edit $SWARM - edit the newly created swarm"
    echo_next "swarm provision $SWARM - provision the newly created swarm"

  fi

fi
