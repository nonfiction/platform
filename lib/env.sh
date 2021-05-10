#!/bin/bash


# ---------------------------------------------------------
# Ensure doctl is installed and authenticated
# ---------------------------------------------------------

# Install doctl (if it isn't already)
if hasnt doctl; then
  
  echo "=> Installing doctl..."
  
  # https://github.com/digitalocean/doctl/releases
  version="1.59.0"
  curl -sL https://github.com/digitalocean/doctl/releases/download/v${version}/doctl-${version}-linux-amd64.tar.gz | tar -xzv
  mv ./doctl /usr/local/bin/doctl

fi

# Check if doctl is already authorized to list droplets
if error "doctl compute droplet list"; then
  
  echo "=> doctl unauthorized"
  
  #  https://cloud.digitalocean.com/account/api/tokens
  DO_AUTH_TOKEN=$(env_or_file DO_AUTH_TOKEN /run/secrets/do_token)
  if undefined "$DO_AUTH_TOKEN"; then
    echo "=> Missing DO_AUTH_TOKEN!"
    echo "Create a Personal Access Token on Digital Ocean and set it to an environment variable named:"
    echo "export DO_TOKEN=\"...\""
    exit 1
  fi     

  echo "=> Authorizing doctl..."
  doctl auth init -t $DO_AUTH_TOKEN 
  
fi  

# DOMAIN from env or secret
DOMAIN=$(env_or_file DOMAIN /run/secrets/domain)
if undefined $DOMAIN; then
  echo "=> Missing DOMAIN!"
  echo "Create a domain name named by Digital Ocean and set it to an environment variable named:"
  echo "export DOMAIN=\"example.com\""
  exit 1
fi

# SSH_KEY from env or secret
SSH_KEY="$(env_or_file SSH_KEY ./ssh_key /run/secrets/ssh_key)"
if undefined $SSH_KEY; then
  echo "=> Missing SSH_KEY!"
  echo "Generate an SSH key and set it to an environment variable named:"
  echo "export SSH_KEY=\"-----BEGIN RSA PRIVATE KEY----- ... \""
  echo "OR save a file in your current directory named: ssh_key"
  exit 1
fi

# SSH_PUB from SSH_KEY
echo "$SSH_KEY" > /tmp/ssh_key
chmod 400 /tmp/ssh_key
SSH_PUB="$(ssh-keygen -y -f /tmp/ssh_key)"
rm /tmp/ssh_key

# ROOT_PASSWORD from env or secret
ROOT_PASSWORD=$(env_or_file ROOT_PASSWORD /run/secrets/root_password)
if undefined $ROOT_PASSWORD; then
  echo "=> Missing ROOT_PASSWORD!"
  echo "Create a root password and set it to an environment variable named:"
  echo "export ROOT_PASSWORD=\"secret\""
  exit 1
fi

# DROPLET_IMAGE from env, or default
# - ubuntu-18-04-x64
# - ubuntu-20-04-x64
if undefined $DROPLET_IMAGE; then
  DROPLET_IMAGE="ubuntu-18-04-x64"
fi

# DROPLET_SIZE from env, or default
# $5/mo: s-1vcpu-1gb
# $15/mo: s-2vcpu-2gb 
if undefined $DROPLET_SIZE; then
  DROPLET_SIZE="s-1vcpu-1gb"
fi

# VOLUME_SIZE from env, or default
if undefined $VOLUME_SIZE; then
  VOLUME_SIZE="50"
fi

# REGION from env, or default
if undefined $REGION; then
  REGION="tor1"
fi

# FS_TYPE from env, or default
if undefined $FS_TYPE; then
  FS_TYPE="ext4"
fi

# First parameter is name of swarm
SWARM="$1"
if undefined $SWARM; then
  echo "=> Missing swarm name!"
  echo "The first argument for this script should be the swarm's name. Example: ./swarm.sh app 3"
  exit 1
fi

# Look up number of existing replicas from $SWARM name, single node swarm is 0
EXISTING_REPLICAS="$(get_droplet_replicas $SWARM | wc -l)"

# Second parameter is number of new replicas, or default 0
NEW_REPLICAS="$2"
undefined $NEW_REPLICAS && NEW_REPLICAS=0