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
	mkdir -p /work /data/platform/{traefik,portainer/{data,config}}
	touch /data/platform/traefik/{traefik.yml,acme.json}
	chmod 600 /data/platform/traefik/acme.json

stack:
	APP=traefik esh stack-traefik.yml > deploy/stack-traefik.yml
	APP=hello-world esh stack-hello-world.yml > deploy/stack-hello-world.yml
	APP=portainer esh stack-portainer-agent.yml > deploy/stack-portainer-agent.yml
	APP=portainer esh stack-portainer.yml > deploy/stack-portainer.yml
	APP=workspace esh stack-workspace.yml > deploy/stack-workspace.yml

pull:
	docker pull nonfiction/traefik:v1
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
