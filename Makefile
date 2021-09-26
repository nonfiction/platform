.PHONY: deploy
SHELL := /bin/bash

all:
	@echo -e "Make commands:"
	@echo -e "\tinit \t\t -- Create data directories & files"
	@echo -e "\tstack \t\t -- Generate compose stacks in deploy directory"
	@echo -e "\tpull \t\t -- Pull docker images"
	@echo -e "\ttraefik \t -- Deploy traefik stack (app role)"
	@echo -e "\tworkspace \t -- Deploy workspace stack (dev role)"

init:
	mkdir -p /work /root/data/{traefik,portainer/{data,config}}
	touch /root/data/traefik/{traefik.yml,acme.json}
	chmod 600 /root/data/traefik/acme.json

stack:
	source swarm/lib/helpers.sh && source swarm/lib/doctl.sh && XDG_CONFIG_HOME=/root/.config verify_doctl
	esh stack-traefik.yml > deploy/stack-traefik.yml
	esh stack-hello-world.yml > deploy/stack-hello-world.yml
	esh stack-portainer-agent.yml > deploy/stack-portainer-agent.yml
	esh stack-portainer.yml > deploy/stack-portainer.yml
	esh stack-workspace.yml > deploy/stack-workspace.yml

pull:
	docker pull traefik:v2.5.3
	docker pull nonfiction/hello-world
	docker pull portainer/portainer-ce
	docker pull portainer/agent
	docker pull nonfiction/workspace

traefik: init stack pull
	docker stack deploy -c deploy/stack-traefik.yml platform
	docker stack deploy -c deploy/stack-hello-world.yml platform
	docker stack deploy -c deploy/stack-portainer-agent.yml platform

workspace: traefik
	docker stack deploy -c deploy/stack-portainer.yml platform
	docker stack deploy --resolve-image never -c deploy/stack-workspace.yml platform
