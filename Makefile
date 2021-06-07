include .env

init: data network

data:
	mkdir -p /work
	# mkdir -p /data/work-cache
	# mkdir -p /data/work-data
	# mkdir -p /data/portainer
	mkdir -p /data/traefik
	mkdir -p /data/portainer
	touch /data/traefik/traefik.yml
	touch /data/traefik/acme.json
	chmod 600 /data/traefik/acme.json

network:
	docker network create --driver=overlay proxy
	docker network create --driver=overlay --attachable dockersocket

dockersocket:
	docker container run -d --privileged -p 127.0.0.1:2375:2375 \
		--name=dockersocket --network=dockersocket \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		-e CONTAINERS=1 \
		-e NETWORKS=1 \
    -e POST=1 \
    -e SERVICES=1 \
    -e SWARM=1 \
    -e TASKS=1 \
    -e NODES=1 \
    tecnativa/docker-socket-proxy

deploy: dockersocket
	# docker stack deploy -c traefik.yml -c hello-world.yml -c portainer.yml $(NODE)
	docker stack deploy -c traefik.yml $(NODE)
	docker stack deploy -c portainer.yml $(NODE)
	docker stack deploy -c hello-world.yml $(NODE)
