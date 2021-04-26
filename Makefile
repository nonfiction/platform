include .env

init: .env data network

.env:
	cp example.env .env

data:
	mkdir -p /work
	mkdir -p data/work-cache
	mkdir -p data/work-data
	mkdir -p data/portainer
	touch data/acme.json
	chmod 600 data/acme.json
	touch data/traefik.yml

network:
	docker network create traefik

up:
	docker-compose up -d
down: 
	docker-compose down

pull: 
	docker-compose pull

logs: 
	docker-compose logs -f
