include .env

init: .env data network

.env:
	cp example.env .env

data:
	mkdir -p data
	touch data/acme.json
	chmod 600 data/acme.json
	touch data/traefik.yml

network:
	docker network create traefik

up: 
	APP_HOST=$(APP_HOST) docker-compose up -d

down: 
	docker-compose down

logs: 
	docker-compose logs -f
