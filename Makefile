init:
	mkdir -p /work
	mkdir -p /data/traefik
	mkdir -p /data/portainer
	touch /data/traefik/traefik.yml
	touch /data/traefik/acme.json
	chmod 600 /data/traefik/acme.json

deploy: stack 
	docker stack deploy -c traefik.yml platform
	docker stack deploy -c hello-world.yml platform
	docker stack deploy -c portainer.yml platform
	docker stack deploy -c workspace.yml platform

stack:
	esh traefik.yml.esh > traefik.yml
	esh hello-world.yml.esh > hello-world.yml
	esh portainer.yml.esh > portainer.yml
	esh workspace.yml.esh > workspace.yml
