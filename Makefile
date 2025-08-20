# ReleaseLens Makefile
# Development and deployment automation

.PHONY: help bootstrap install clean
.PHONY: lint format test test-integration test-e2e
.PHONY: run-api run-worker run-all stop-all
.PHONY: seed-knowledge clean-runs backup-qdrant
.PHONY: eval eval-quick benchmark demo demo-record
.PHONY: build deploy-staging deploy-prod logs shell

# Default target
help:
	@echo "ReleaseLens Development Commands"
	@echo "================================"
	@echo ""
	@echo "Development Setup:"
	@echo "  bootstrap       - Install dependencies and setup pre-commit"
	@echo "  install         - Install dependencies only"
	@echo "  clean           - Clean build artifacts and caches"
	@echo ""
	@echo "Code Quality:"
	@echo "  lint            - Run all linters (ruff, black, isort, mypy)"
	@echo "  format          - Format code with black and isort"
	@echo ""
	@echo "Testing:"
	@echo "  test            - Run unit tests with coverage"
	@echo "  test-integration- Run integration tests"
	@echo "  test-e2e        - Run end-to-end tests"
	@echo ""
	@echo "Services:"
	@echo "  run-api         - Start FastAPI server in development"
	@echo "  run-worker      - Start background worker"
	@echo "  run-all         - Start all services with Docker Compose"
	@echo "  stop-all        - Stop all Docker services"
	@echo ""
	@echo "Data Management:"
	@echo "  seed-knowledge  - Populate Qdrant with initial dataset"
	@echo "  clean-runs      - Clean all run artifacts"
	@echo "  backup-qdrant   - Create Qdrant snapshot"
	@echo ""
	@echo "Evaluation:"
	@echo "  eval            - Run full evaluation suite"
	@echo "  eval-quick      - Run quick evaluation on sample"
	@echo "  benchmark       - Run performance benchmarks"
	@echo ""
	@echo "Demo:"
	@echo "  demo            - Run interactive demo"
	@echo "  demo-record     - Record demo screencast"
	@echo ""
	@echo "Deployment:"
	@echo "  build           - Build production containers"
	@echo "  deploy-staging  - Deploy to staging environment"
	@echo "  deploy-prod     - Deploy to production environment"
	@echo ""
	@echo "Utilities:"
	@echo "  logs            - Show service logs"
	@echo "  shell           - Open shell in API container"

# Development Setup
bootstrap: install
	pre-commit install
	@echo "✅ Development environment ready!"

install:
	pip install -e .[dev]
	@echo "✅ Dependencies installed!"

clean:
	docker system prune -f
	rm -rf .pytest_cache/
	rm -rf .mypy_cache/
	rm -rf .ruff_cache/
	rm -rf htmlcov/
	rm -rf dist/
	rm -rf build/
	find . -type d -name __pycache__ -delete
	find . -type f -name "*.pyc" -delete
	@echo "✅ Cleaned build artifacts!"

# Code Quality
lint:
	ruff check .
	black --check .
	isort --check-only .
	mypy .
	@echo "✅ All linting passed!"

format:
	black .
	isort .
	ruff check . --fix
	@echo "✅ Code formatted!"

# Testing
test:
	pytest -v --cov=src --cov-report=html --cov-report=term-missing

test-integration:
	pytest tests/integration/ -v --slow

test-e2e:
	pytest tests/e2e/ -v --slow

# Services
run-api:
	uvicorn api.main:app --reload --port 8000

run-worker:
	python worker/main.py

run-all:
	docker compose up --build -d
	@echo "✅ All services started! API: http://localhost:8000"

stop-all:
	docker compose down -v
	@echo "✅ All services stopped!"

# Data Management
seed-knowledge:
	python scripts/seed_qdrant.py --packages requests,django,pandas,fastapi,pydantic

clean-runs:
	rm -rf runs/*
	@echo "✅ Run artifacts cleaned!"

backup-qdrant:
	docker exec releaselens-qdrant-1 /qdrant/qdrant --snapshot create || echo "⚠️  Qdrant container not running"

# Evaluation
eval:
	python eval/harness.py --dataset eval/datasets/full.json

eval-quick:
	python eval/harness.py --dataset eval/datasets/sample.json

benchmark:
	python eval/benchmark.py --runs 10

# Demo
demo:
	python scripts/run_demo.py

demo-record:
	python scripts/run_demo.py --record --output docs/demo.mp4

# Deployment
build:
	docker compose -f docker-compose.prod.yml build

deploy-staging:
	docker compose -f docker-compose.staging.yml up -d

deploy-prod:
	docker compose -f docker-compose.prod.yml up -d

# Utilities
logs:
	docker compose logs -f

shell:
	docker compose exec api bash