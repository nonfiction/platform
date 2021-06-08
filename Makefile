include .env

# make traefik to build and push this customized image to docker hub
traefik:
	docker build -t nonfiction/traefik:v2.4.8 .
	docker push nonfiction/traefik:v2.4.8

init: data network

data:
	mkdir -p /work
	mkdir -p /data/traefik
	mkdir -p /data/portainer
	touch /data/traefik/traefik.yml
	touch /data/traefik/acme.json
	chmod 600 /data/traefik/acme.json

network:
	docker network create --driver=overlay proxy

deploy: 
	docker stack deploy -c traefik.yml $(NODE)
	docker stack deploy -c portainer.yml $(NODE)
	docker stack deploy -c hello-world.yml $(NODE)
