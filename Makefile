include .env

init: data network

data:
	mkdir -p /work
	# mkdir -p /data/work-cache
	# mkdir -p /data/work-data
	# mkdir -p /data/portainer
	mkdir -p /data/traefik
	touch /data/traefik/traefik.yml
	touch /data/traefik/acme.json
	chmod 600 /data/traefik/acme.json

network:
	#docker network create --driver=overlay proxy

deploy:
	docker stack deploy -c traefik.yml $(NODE)
	docker stack deploy -c hello-world.yml $(NODE)
