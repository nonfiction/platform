# Docker Host

## Steps

### 1. Create droplet

[Ubuntu 18.04.3 LTS](https://cloud.digitalocean.com/droplets/new?fleetUuid=12c6d9bb-b1ea-4af7-b322-651589b09d8e&i=bc4e87&size=s-2vcpu-4gb&region=tor1&distro=ubuntu&distroImage=ubuntu-18-04-x64&options=backups,install_agent)

- Select SSH keys
- Enter hostname (app1.example.com)
- Add tag "docker"
- If the DNS record you want already exists, delete it from Digital Ocean before proceeding

### 2. Run setup script

Login to droplet `ssh root@DROPLET.IP.ADDRESS`, complete these variables, and run this script:

    export APP_HOST=app1
    export DOMAIN=exmaple.com
    export DO_AUTH_TOKEN=
    export BASICAUTH=
    curl -sSL https://gist.github.com/suderman/79cf2ede48eabd05e09555db8be89a3a/raw/docker-host.sh | bash

Click yes to any prompts. Let's Encrypt certificates sometimes take a while. It's also a good time to reboot while the server is fresh.
