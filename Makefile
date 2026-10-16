.DEFAULT_GOAL := help
.PHONY: help setup up down logs shell db-shell lint fmt test build-prod reset

-include .env
APP_PORT ?= 8080
DEBUG_PORT ?= 5005

help:  ## Lista os comandos disponíveis
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

setup:  ## Prepara o projeto pela primeira vez (.env, hooks, build)
	@test -f .env || cp .env.example .env
	git config core.hooksPath .githooks
	docker compose build

up:  ## Sobe o ambiente (app + Postgres)
	docker compose up -d
	@echo "API em http://localhost:$(APP_PORT) | health: http://localhost:$(APP_PORT)/actuator/health | debug: localhost:$(DEBUG_PORT)"

down:  ## Derruba o ambiente
	docker compose down

logs:  ## Acompanha os logs da aplicação
	docker compose logs -f app

shell:  ## Abre um shell dentro do container da aplicação
	docker compose exec app sh

db-shell:  ## Abre o psql no banco de desenvolvimento
	docker compose exec db sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

lint:  ## Verifica a formatação do código (Spotless)
	docker compose exec -T app ./mvnw -q -B spotless:check

fmt:  ## Formata o código (Spotless)
	docker compose exec -T app ./mvnw -q -B spotless:apply

test:  ## Roda os testes
	@echo "Ainda não há testes configurados. Próximo passo: JUnit + Testcontainers."

build-prod:  ## Gera a imagem de produção (estágio prod do Dockerfile)
	docker build --target prod -t payment-orchestrator:local .

reset:  ## Derruba tudo e apaga os volumes (destrói os dados locais)
	docker compose down -v
