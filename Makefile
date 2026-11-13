.PHONY: up down build rebuild logs shell url

up:
	docker compose up -d

down:
	docker compose down

build:
	docker compose build

rebuild:
	docker compose build --no-cache && docker compose up -d

logs:
	docker compose logs -f

shell:
	docker compose exec jupyterlab bash

url:
	@docker compose exec jupyterlab jupyter server list
