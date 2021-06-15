# nonfiction Platform

## Setup

- Create domain
- Create firewall
- Create "swarm" tag

## Usage:

Create and manage swarms from the command line:

```

# Create new swarmfile:
swarm create abc.example.com

# Edit this swarmfile:
swarm edit abc.example.com

# Provision resources on Digital Ocean:
swarm provision abc.example.com

# Provision three replicas:
swarm provision abc.example.com +3

# Remove specific replica:
swarm provision abc.example.com -abc02

# Run node configuration and deploy this swarm:
swarm deploy abc.example.com

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
