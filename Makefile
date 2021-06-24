init:
	mkdir -p /work
	mkdir -p /data/platform/traefik
	mkdir -p /data/platform/portainer
	touch /data/platform/traefik/traefik.yml
	touch /data/platform/traefik/acme.json
	chmod 600 /data/platform/traefik/acme.json

stack:
	esh traefik.yml.esh > traefik.yml
	esh traefik.yml.esh > caddy.yml
	esh hello-world.yml.esh > hello-world.yml
	esh portainer-agent.yml.esh > portainer-agent.yml
	esh portainer.yml.esh > portainer.yml
	esh workspace.yml.esh > workspace.yml

pull:
	docker pull nonfiction/traefik
	docker pull nonfiction/hello-world
	docker pull portainer/portainer-ce
	docker pull portainer/agent
	docker pull nonfiction/workspace

deploy: init stack pull
	docker stack deploy -c traefik.yml platform
	docker stack deploy -c hello-world.yml platform
	docker stack deploy -c portainer-agent.yml platform

proxy: init stack pull
	docker stack deploy -c caddy.yml platform
	docker stack deploy -c hello-world.yml platform
	docker stack deploy -c portainer-agent.yml platform

workspace: deploy
	docker stack deploy -c portainer.yml platform
	docker stack deploy -c workspace.yml platform
