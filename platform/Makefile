# TrustOS platform — dev entrypoints. All targets run from this directory.
COMPOSE := docker compose -f docker-compose.dev.yml

.PHONY: install lint typecheck test up down

install:
	uv sync

lint:
	uv run ruff check .

typecheck:
	uv run mypy

test:
	uv run pytest

up:
	$(COMPOSE) up -d --wait

down:
	$(COMPOSE) down -v
