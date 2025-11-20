PYTHON := python3
POETRY := poetry
APP := app.main:app
PORT ?= 8080

.PHONY: install run lint fmt test

install:
	$(POETRY) install --sync

run:
	$(POETRY) run uvicorn $(APP) --host 0.0.0.0 --port $(PORT)

lint:
	$(POETRY) run ruff check app tests

fmt:
	$(POETRY) run ruff format app tests

test:
	$(POETRY) run pytest -q
