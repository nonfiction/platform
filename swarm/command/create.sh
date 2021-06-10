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

    # Download the template
    rm -rf /tmp/swarmfile
    curl -sL https://github.com/nonfiction/platform/raw/main/swarm/template/swarmfile > /tmp/swarmfile

    # Fill in the blanks
    sed -i "s|__NODE__|${NODE}|g" /tmp/swarmfile
    sed -i "s|__DOMAIN__|${DOMAIN}|g" /tmp/swarmfile

    echo_next "Creating SWARMFILE: ${SWARMFILE}"

    echo_main_alt "Droplet Details"

    ask_input DROPLET_IMAGE
    DROPLET_IMAGE=$(ask_env_file_default DROPLET_IMAGE /usr/local/env/DROPLET_IMAGE "ubuntu-20-04-x64")
    sed -i "s|__DROPLET_IMAGE__|${DROPLET_IMAGE}|g" /tmp/swarmfile
    echo_env DROPLET_IMAGE

    ask_input REGION
    DROPLET_IMAGE=$(ask_env_file_default REGION /usr/local/env/REGION "tor1")
    sed -i "s|__REGION__|${REGION}|g" /tmp/swarmfile
    echo_env REGION
    
    ask_input FS_TYPE
    FS_TYPE=$(ask_env_file_default FS_TYPE /usr/local/env/REGION "ext4")
    sed -i "s|__FS_TYPE__|${FS_TYPE}|g" /tmp/swarmfile
    echo_env FS_TYPE

    # Generate SSH key (base64-encoded)
    sed -i "s|__ROOT_PRIVATE_KEY__|$(generate_key)|g" /tmp|swarmfile
    sed -i "s|__ROOT_PASSWORD__|$(generate_password)|g" /tmp/swarmfile


    echo_main_alt "Digital Ocean: personal access token"
    echo "https://cloud.digitalocean.com/account/api/tokens"

    ask_input DO_AUTH_TOKEN
    DO_AUTH_TOKEN=$(ask_env_file_default DO_AUTH_TOKEN /usr/local/env/DO_AUTH_TOKEN)
    sed -i "s|__DO_AUTH_TOKEN__|${DO_AUTH_TOKEN}|g" /tmp/swarmfile
    echo_env DO_AUTH_TOKEN


    echo_main_alt "Webhook is called by the swarm manager to signal when nodes are ready"
    echo "https://api.slack.com/messaging/webhooks"

    ask_input WEBHOOK
    WEBHOOK=$(ask_env_file_default WEBHOOK /usr/local/env/WEBHOOK)
    sed -i "s|__WEBHOOK__|${WEBHOOK}|g" /tmp/swarmfile
    echo_env WEBHOOK


    echo_main_alt "Git config info"
    echo "If this swarm is used for development, who is writing these commits?"

    ask_input GIT_USER_NAME
    GIT_USER_NAME=$(ask_env_file_default GIT_USER_NAME /usr/local/env/GIT_USER_NAME)
    sed -i "s|__GIT_USER_NAME__|${GIT_USER_NAME}|g" /tmp/swarmfile
    echo_env GIT_USER_NAME

    ask_input GIT_USER_EMAIL
    GIT_USER_EMAIL=$(ask_env_file_default GIT_USER_EMAIL /usr/local/env/GIT_USER_EMAIL)
    sed -i "s|__GIT_USER_EMAIL__|${GIT_USER_EMAIL}|g" /tmp/swarmfile
    echo_env GIT_USER_EMAIL

    echo_main_alt "Github account"
    echo "https://github.com/settings/tokens"

    ask_input GITHUB_USER
    GITHUB_USER=$(ask_env_file_default GITHUB_USER /usr/local/env/GITHUB_USER)
    sed -i "s|__GITHUB_USER__|${GITHUB_USER}|g" /tmp/swarmfile
    echo_env GITHUB_USER

    ask_input GITHUB_TOKEN
    GITHUB_TOKEN=$(ask_env_file_default GITHUB_TOKEN /usr/local/env/GITHUB_TOKEN)
    sed -i "s|__GITHUB_TOKEN__|${GITHUB_TOKEN}|g" /tmp/swarmfile
    echo_env GITHUB_TOKEN


    echo_main_alt "VS Code password"
    echo "This really ought to be a complicated password"

    ask_input CODE_PASSWORD
    CODE_PASSWORD=$(ask_env_file_default CODE_PASSWORD /usr/local/env/CODE_PASSWORD $(generate_password))
    sed -i "s|__CODE_PASSWORD__|${CODE_PASSWORD}|g" /tmp/swarmfile 


    echo_main_alt "Sudo password"
    echo "Choose something you don't mind typing regularily"

    ask_input SUDO_PASSWORD
    SUDO_PASSWORD=$(ask_env_file_default SUDO_PASSWORD /usr/local/env/SUDO_PASSWORD $(generate_password))
    sed -i "s|__SUDO_PASSWORD__|${SUDO_PASSWORD}|g" /tmp/swarmfile 


    echo_main_alt "Digital Ocean: database cluster"
    echo "https://cloud.digitalocean.com/databases"

    ask_input DB_HOST
    DB_HOST=$(ask_env_file_default DB_HOST /usr/local/env/DB_HOST)
    sed -i "s|__DB_HOST__|${DB_HOST}|g" /tmp/swarmfile
    echo_env DB_HOST

    ask_input DB_PORT
    DB_PORT=$(ask_env_file_default DB_PORT /usr/local/env/DB_PORT "25060")
    sed -i "s|__DB_PORT__|${DB_PORT}|g" /tmp/swarmfile
    echo_env DB_PORT

    ask_input DB_USER
    DB_USER=$(ask_env_file_default DB_USER /usr/local/env/DB_USER "doadmin")
    sed -i "s|__DB_USER__|${DB_USER}|g" /tmp/swarmfile
    echo_env DB_USER

    ask_input DB_PASSWORD
    DB_PASSWORD=$(ask_env_file_default DB_PASSWORD /usr/local/env/DB_PASSWORD)
    sed -i "s|__DB_PASSWORD__|${DB_PASSWORD}|g" /tmp/swarmfile
    echo_env DB_PASSWORD

    echo_main_alt "BasicAuth login"
    echo "This may need to be shared with clients occasionally"

    ask_input BASICAUTH_USER
    BASICAUTH_USER=$(ask_env_file_default BASICAUTH_USER /usr/local/env/BASICAUTH_USER "nonfiction")
    sed -i "s|__BASICAUTH_USER__|${BASICAUTH_USER}|g" /tmp/swarmfile
    echo_env BASICAUTH_USER

    ask_input BASICAUTH_PASSWORD
    BASICAUTH_PASSWORD=$(ask_env_file_default BASICAUTH_PASSWORD /usr/local/env/BASICAUTH_PASSWORD $(generate_password))
    sed -i "s|__BASICAUTH_PASSWORD__|${BASICAUTH_PASSWORD}|g" /tmp/swarmfile
    echo_env BASICAUTH_PASSWORD


    # Confirm
    if ask "Save?"; then  

      # Save from tmp to where it belongs
      mv /tmp/swarmfile $SWARMFILE

    else
      echo_stop "Cancelled."  
      rm -f /tmp/swarmfile
      exit 1;
    fi

    echo_info "...done!"
    echo_next "swarm edit $SWARM - edit the newly created swarm"
    echo_next "swarm provision $SWARM - provision the newly created swarm"

  fi

fi
