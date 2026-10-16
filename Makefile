.DEFAULT_GOAL := help
.PHONY: help setup up down logs shell db-shell lint fmt test build-prod reset

-include .env
APP_PORT ?= 8080
DEBUG_PORT ?= 5005

help:  ## List available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

setup:  ## First-time project setup (.env, hooks, build)
	@test -f .env || cp .env.example .env
	git config core.hooksPath .githooks
	docker compose build

up:  ## Start the environment (app + Postgres)
	docker compose up -d
	@echo "API at http://localhost:$(APP_PORT) | health: http://localhost:$(APP_PORT)/actuator/health | debug: localhost:$(DEBUG_PORT)"

down:  ## Stop the environment
	docker compose down

logs:  ## Follow application logs
	docker compose logs -f app

shell:  ## Open a shell inside the app container
	docker compose exec app sh

db-shell:  ## Open psql on the development database
	docker compose exec db sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

lint:  ## Check code formatting (Spotless)
	docker compose exec -T app ./mvnw -q -B spotless:check

fmt:  ## Format code (Spotless)
	docker compose exec -T app ./mvnw -q -B spotless:apply

test:  ## Run tests
	@echo "No tests configured yet. Next step: JUnit + Testcontainers."

build-prod:  ## Build the production image (Dockerfile prod stage)
	docker build --target prod -t payment-orchestrator:local .

reset:  ## Stop everything and delete volumes (destroys local data)
	docker compose down -v
