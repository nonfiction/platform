#!/bin/bash

# export APP_HOST=
# export DOMAIN=
# export DO_AUTH_TOKEN=
# export BASICAUTH=

# export DEBIAN_FRONTEND=noninteractive

# Upgrade OS
apt-get update
apt-get --yes upgrade

# Install deps
apt-get --yes install zsh mosh fail2ban build-essential apt-transport-https ca-certificates gnupg-agent software-properties-common curl make unzip apache2-utils davfs2 

# Automatic Security patches
apt-get --yes install unattended-upgrades
dpkg-reconfigure --priority=low unattended-upgrades

# Name the server
hostnamectl set-hostname ${APP_HOST}.${DOMAIN}

# Optimize SSH for Docker
echo "MaxSessions 500" >> /etc/ssh/sshd_config
service ssh restart

# Get droplet IP adress
IP=$(curl -s http://checkip.amazonaws.com/)

# Prepare components of Digital Ocean API 
JSON="Content-Type: application/json"
AUTH="Authorization: Bearer ${DO_AUTH_TOKEN}"
URL=https://api.digitalocean.com/v2/domains/${DOMAIN}/records

# Create domain records for APP_HOST as well as wildcard (if they don't yet exist)
for NAME in ${APP_HOST} *.${APP_HOST}; do
  record_exists=$(curl -X GET -H "$JSON" -H "$AUTH" "${URL}?type=A&name=${NAME}.${DOMAIN}" | grep $IP)
  [ -z "$record_exists" ] && curl -X POST -H "$JSON" -H "$AUTH" -d "{\"type\":\"A\",\"name\":\"${NAME}\",\"data\":\"${IP}\"}" $URL
done;

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update && apt-get --yes install docker-ce docker-ce-cli containerd.io

# Install Docker Compose
COMPOSE_VERSION=$(git ls-remote https://github.com/docker/compose | grep refs/tags | grep -oP "[0-9]+\.[0-9][0-9]+\.[0-9]+$" | sort --version-sort | tail -n 1)
curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
curl -L https://raw.githubusercontent.com/docker/compose/$COMPOSE_VERSION/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose

# Install docker-host
git clone https://github.com/nonfiction/docker-host.git /root/docker-host
cd /root/docker-host && make init
echo "APP_HOST=${APP_HOST}.${DOMAIN}" > /root/docker-host/.env 
echo "BASICAUTH=${BASICAUTH}" >> /root/docker-host/.env 
echo "DO_AUTH_TOKEN=${DO_AUTH_TOKEN}" >> /root/docker-host/.env
echo "GIT_USER_NAME=${GIT_USER_NAME}" >> /root/docker-host/.env
echo "GIT_USER_EMAIL=${GIT_USER_EMAIL}" >> /root/docker-host/.env
echo "CODE_PASSWORD=${CODE_PASSWORD}" >> /root/docker-host/.env
echo "SUDO_PASSWORD=${SUDO_PASSWORD}" >> /root/docker-host/.env
echo "DB_USER=${DB_USER}" >> /root/docker-host/.env
echo "DB_PASSWORD=${DB_PASSWORD}" >> /root/docker-host/.env
echo "DB_HOST=${DB_HOST}" >> /root/docker-host/.env
echo "DB_PORT=${DB_PORT}" >> /root/docker-host/.env

cd /root/docker-host && make up

# Auto-prune Docker with cron
echo "0 3 * * * root /usr/bin/docker system prune -f > /dev/null 2>&1" >> /etc/crontab
service cron start

echo "...done! You may want to reboot."
