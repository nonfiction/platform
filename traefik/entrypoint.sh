#!/bin/sh
set -e

# https://github.com/containous/traefik-library-image/blob/master/alpine/entrypoint.sh
# nf 

# decode ssh key and save to file with proper permissions
echo "$ROOT_PRIVATE_KEY" | base64 -d > /root/.ssh/id_rsa
touch /root/.ssh/id_rsa && chmod 400 /root/.ssh/id_rsa

# add key to ssh-agent
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa

# /nf

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- traefik "$@"
fi

# if our command is a valid Traefik subcommand, let's invoke it through Traefik instead
# (this allows for "docker run traefik version", etc)
if traefik "$1" --help >/dev/null 2>&1
then
    set -- traefik "$@"
else
    echo "= '$1' is not a Traefik command: assuming shell execution." 1>&2
fi

exec "$@"
