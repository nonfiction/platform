.PHONY: deploy

all:
	@echo init
	@echo stack
	@echo pull
	@echo caddy
	@echo traefik
	@echo workspace
	@echo ""

init:
	mkdir -p /work
	mkdir -p /data/platform/traefik
	mkdir -p /data/platform/portainer
	mkdir -p /data/platform/caddy/data
	mkdir -p /data/platform/caddy/config
	touch /data/platform/traefik/traefik.yml
	touch /data/platform/traefik/acme.json
	chmod 600 /data/platform/traefik/acme.json

stack:
	APP=traefik esh stack-traefik.yml > deploy/traefik.yml
	APP=caddy esh stack-caddy.yml > deploy/caddy.yml
	APP=hello-world esh stack-hello-world.yml > deploy/hello-world.yml
	APP=portainer esh stack-portainer-agent.yml > deploy/portainer-agent.yml
	APP=portainer esh stack-portainer.yml > deploy/portainer.yml
	APP=workspace esh stack-workspace.yml > deploy/workspace.yml

pull:
	docker pull nonfiction/traefik
	docker pull nonfiction/hello-world
	docker pull portainer/portainer-ce
	docker pull portainer/agent
	docker pull caddy
	docker pull nonfiction/workspace

caddy: init stack pull
	docker stack deploy -c deploy/caddy.yml platform
	docker stack deploy -c deploy/hello-world.yml platform
	docker stack deploy -c deploy/portainer-agent.yml platform

traefik: init stack pull
	docker stack deploy -c deploy/traefik.yml platform
	docker stack deploy -c deploy/hello-world.yml platform
	docker stack deploy -c deploy/portainer-agent.yml platform

workspace: traefik
	docker stack deploy -c deploy/portainer.yml platform
	docker stack deploy --resolve-image never -c deploy/workspace.yml platform
