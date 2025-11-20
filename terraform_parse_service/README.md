# Terraform Parse Service

Minimal FastAPI service that turns validated JSON payloads into Terraform templates.

## Requirements
- Python 3.11+
- [Poetry](https://python-poetry.org/) 1.7+

## Setup
```bash
poetry install
```

## Run locally
```bash
poetry run uvicorn app.main:app --reload --port 8080
```

## Test
```bash
poetry run pytest
```
