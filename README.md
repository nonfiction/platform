# nonfiction Platform

Configuration for [Docker Swarm](https://docs.docker.com/engine/swarm/) with
[GlusterFS](https://docs.gluster.org/) distributed file system, provisioned
by Digital Ocean's [doctl](https://github.com/digitalocean/doctl). Deployed swarms 
will run [Traefik](https://doc.traefik.io/traefik/) as reverse proxy for Docker 
services, as well as [VS Code](https://github.com/cdr/code-server) in an 
[Alpine](https://www.alpinelinux.org) environment for development.

This platform isn't intended to be installed on an existing system. Instead, it
includes a `swarm` CLI tool which provisions a cluster of servers from Digital
Ocean and installs itself there. 

```
# Create new swarmfile:
swarm create abc.example.com

# Provision resources:
swarm provision abc.example.com

# After 5-10 minutes, deploy swarm:
swarm deploy abc.example.com
```

Since `swarm` is just a Bash script, a new cluster can be bootstrapped from any
terminal like so:

```
# Create new swarmfile:
bash <(curl -fsSL https://github.com/nonfiction/platform/raw/main/swarm/swarm) create abc.example.com

# Provision resources:
bash <(curl -fsSL https://github.com/nonfiction/platform/raw/main/swarm/swarm) provision abc.example.com

# After 5-10 minutes, deploy swarm:
bash <(curl -fsSL https://github.com/nonfiction/platform/raw/main/swarm/swarm) deploy abc.example.com
```

## Digital Ocean Setup

- Create new tag `swarm` by adding it to an arbitrary [droplet](https://cloud.digitalocean.com/droplets)
- APIs -> Tokens/Keys -> [Generate New Token](https://cloud.digitalocean.com/account/api/tokens)
- Networking -> Domains -> [Add Domain](https://cloud.digitalocean.com/networking/domains/)
- Networking -> Firewalls -> [Create Firewall](https://cloud.digitalocean.com/networking/firewalls)

![11EB4F4A-2562-4860-A4CA-4798C4866996](https://user-images.githubusercontent.com/12491/122124309-552e3680-cdec-11eb-8cd9-abe1613992fa.jpeg)

## Usage:

Create and manage swarms from the command line:

```
# Create new swarmfile:
swarm create abc.example.com

# Edit swarmfile:
swarm edit abc.example.com

# Import swarmfile:
swarm import xyz.example.com

# Export swarmfile:
swarm export xyz.example.com

# Provision resources:
swarm provision abc.example.com

# After 5-10 minutes, deploy swarm:
swarm deploy abc.example.com

# Provision three replicas:
swarm provision abc.example.com +3

# Remove specific replica:
swarm provision abc.example.com -abc02

# SSH into the first replica of this swarm:
swarm ssh abc.nfweb.ca abc01

# List these commands:
swarm help
```

These are to be run on a separate server not involved in the swarm being managed: 

```
# Promote replica to primary:
swarm provision abc.example.com ^abc01

# Increase each node's volume size to 20GB:
swarm size abc.example.com 20

# Increase each node's droplet memory to 2GB:
swarm size abc.example.com s-1vcpu-2gb

# Remove a swarm
swarm remove abc.example.com
```

## Makefile commands:  

These are to be run on the primary node in the swarm:

```
make init
make stack
make pull
make deploy
```

## Related Repositories

- [nonfiction/traefik](https://github.com/nonfiction/traefik)
- [nonfiction/workspace](https://github.com/nonfiction/workspace)
- [nonfiction/hello-world](https://github.com/nonfiction/hello-world)
- [nonfiction/wordpress](https://github.com/nonfiction/wordpress)

