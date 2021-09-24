#!/bin/bash

# Usage examples
# -----------------------
#
# # Add two replicas:
# nf swarm provision <%= ${NODE}.${DOMAIN} %> +2
#
# # Remove specific replica:
# nf swarm provision <%= ${NODE}.${DOMAIN} %> -<%= $NODE %>02
#
# # Increase the volume size to 20GB:
# nf swarm size <%= ${NODE}.${DOMAIN} %> 20
#
# # Run node configuration and deploy this swarm:
# nf swarm deploy <%= ${NODE}.${DOMAIN} %>
#
# # SSH into the first replica in this swarm:
# nf swarm ssh <%= ${NODE}.${DOMAIN} %> <%= $NODE %>01


# Workspace configuration
# -----------------------

# Identifies git commits on this workspace
export GIT_USER_NAME="<%= $GIT_USER_NAME %>"
export GIT_USER_EMAIL=<%= $GIT_USER_EMAIL %>

# Github account
# https://github.com/settings/tokens
export GITHUB_USER=<%= $GITHUB_USER %>
export GITHUB_TOKEN=<%= $GITHUB_TOKEN %>

# Login password for VS Code/code-server
export CODE_PASSWORD=<%= $CODE_PASSWORD %>

# sudo password for "work" user in workspace
export SUDO_PASSWORD=<%= $SUDO_PASSWORD %>

# External database cluster credentials
# https://cloud.digitalocean.com/databases
export DB_HOST=<%= $DB_HOST %>
export DB_PORT=<%= $DB_PORT %>
export DB_ROOT_USER=<%= $DB_ROOT_USER %>
export DB_ROOT_PASSWORD=<%= $DB_ROOT_PASSWORD %>

# External redis cluster credentials
# https://cloud.digitalocean.com/databases
export CACHE_HOST=<%= $CACHE_HOST %>
export CACHE_PORT=<%= $CACHE_PORT %>
export CACHE_PASSWORD=<%= $CACHE_PASSWORD %>

# External SMTP mail server credentials
# https://app.sendgrid.com/settings/api_keys
export SMTP_HOST=<%= $SMTP_HOST %>
export SMTP_PORT=<%= $SMTP_PORT %>
export SMTP_USER=<%= $SMTP_USER %>
export SMTP_PASSWORD=<%= $SMTP_PASSWORD %>


# Node configuration
# -----------------------

# Used by doctl for swarm management & traefik for certificate renewals
export DO_AUTH_TOKEN=<%= $DO_AUTH_TOKEN %>

# Private images are pushed/pulled from here
export DOCKER_REGISTRY=<%= $DOCKER_REGISTRY %>

# All nodes in the swarm are have this root password
export ROOT_PASSWORD=<%= $ROOT_PASSWORD %>

# Password-protected pages like traefik dashboard
export BASICAUTH_USER=<%= $BASICAUTH_USER %>
export BASICAUTH_PASSWORD=<%= $BASICAUTH_PASSWORD %>

# This is called by the swarm manager to signal when nodes are ready
# https://api.slack.com/messaging/webhooks
export WEBHOOK=<%= $WEBHOOK %>


# Swarm configuration
# These settings cannot be modified after the swarm has been created
# -----------------------

export DROPLET_IMAGE=<%= $DROPLET_IMAGE %>
export REGION=<%= $REGION %>
export FS_TYPE=<%= $FS_TYPE %>

# dev/app/lb
export ROLE=<%= $ROLE %>

# All nodes in the swarm are accesible via this private key
export ROOT_PRIVATE_KEY=<%= $ROOT_PRIVATE_KEY %>
