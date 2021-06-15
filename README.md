# nonfiction Platform

## Setup

- Create domain
- Create firewall
- Create "swarm" tag

## Usage:

These are to be run on a separate server not involved in the swarm: 

```

# Create new swarmfile:
swarm create abc.example.com

# Provision resources on Digital Ocean:
swarm provision abc.example.com

# Provision three replicas:
swarm provision abc.example.com +3

# Remove specific replica:
swarm provision abc.example.com -abc02

# Promote replica to primary:
swarm provision abc.example.com ^abc01

# Increase the volume size to 20GB:
swarm size abc.example.com 20

# Run node configuration and deploy this swarm:
swarm deploy abc.example.com

# List these commands and more:
swarm help

```

## Makefile commands:  

These are to be run on the primary node in the swarm:

```
make init
make stack
make deploy
```
