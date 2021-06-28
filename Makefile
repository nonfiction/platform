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
	APP=traefik esh traefik.yml.esh > traefik.yml
	APP=caddy esh caddy.yml.esh > caddy.yml
	APP=hello-world esh hello-world.yml.esh > hello-world.yml
	APP=portainer esh portainer-agent.yml.esh > portainer-agent.yml
	APP=portainer esh portainer.yml.esh > portainer.yml
	APP=workspace esh workspace.yml.esh > workspace.yml

pull:
	docker pull nonfiction/traefik
	docker pull nonfiction/hello-world
	docker pull portainer/portainer-ce
	docker pull portainer/agent
	docker pull caddy
	docker pull nonfiction/workspace

deploy: init stack pull
	docker stack deploy -c traefik.yml platform
	docker stack deploy -c hello-world.yml platform
	docker stack deploy -c portainer-agent.yml platform

load-balancer: init stack pull
	docker stack deploy -c caddy.yml platform
	docker stack deploy -c hello-world.yml platform
	docker stack deploy -c portainer-agent.yml platform

workspace: deploy
	docker stack deploy -c portainer.yml platform
	docker stack deploy --resolve-image never -c workspace.yml platform
