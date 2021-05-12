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
    echo "export DO_AUTH_TOKEN=\"...\""
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

# ROOT_PRIVATE_KEY from env or secret
ROOT_PRIVATE_KEY="$(env_or_file ROOT_PRIVATE_KEY ./root_private_key /run/secrets/root_private_key)"
if undefined $ROOT_PRIVATE_KEY; then
  echo "=> Missing ROOT_PRIVATE_KEY!"
  echo "Generate an SSH key and set it to an environment variable named:"
  echo "export ROOT_PRIVATE_KEY=\"-----BEGIN RSA PRIVATE KEY----- ... \""
  echo "OR save a file in your current directory named: root_private_key"
  exit 1
fi

# ROOT_PUBLIC_KEY from ROOT_PRIVATE_KEY
echo "$ROOT_PRIVATE_KEY" > root_private_key.tmp
chmod 400 root_private_key.tmp
ROOT_PUBLIC_KEY="$(ssh-keygen -y -f root_private_key.tmp) root"
rm -f root_private_key.tmp

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
  VOLUME_SIZE="10"
fi

# REGION from env, or default
if undefined $REGION; then
  REGION="tor1"
fi

# FS_TYPE from env, or default
if undefined $FS_TYPE; then
  FS_TYPE="ext4"
fi