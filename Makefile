# Makefile for BMW iDrive 6 Local Setup

.PHONY: help docker-build docker-up docker-down docker-logs docker-clean shell test

help:
	@echo "BMW iDrive 6 Local Setup"
	@echo ""
	@echo "Available commands:"
	@echo "  make docker-build  - Build Docker image"
	@echo "  make docker-up     - Start Docker container"
	@echo "  make docker-down   - Stop Docker container"
	@echo "  make docker-logs   - View Docker logs"
	@echo "  make docker-clean  - Remove Docker container and image"
	@echo "  make shell         - Open shell in running container"
	@echo "  make run-local     - Run local HTTP server (non-Docker)"
	@echo "  make test          - Test if web interface is accessible"

docker-build:
	docker-compose build

docker-up:
	docker-compose up -d
	@echo ""
	@echo "iDrive 6 web interface is now running at:"
	@echo "  http://localhost:8080/"
	@echo "  http://localhost:8080/journaline.html"

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f

docker-clean:
	docker-compose down -v --rmi all

shell:
	docker-compose exec idrive-web /bin/bash

run-local:
	./run-idrive-local.sh

test:
	@echo "Testing web interface..."
	@curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8080/ || echo "Web interface not accessible. Is it running?"

