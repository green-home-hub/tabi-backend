# Tabi Backend - Makefile
# Provides convenient shortcuts for common development tasks

.PHONY: help build start stop restart status logs test clean dev init setup docs version
.DEFAULT_GOAL := help

# Colors for make output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
CYAN := \033[0;36m
NC := \033[0m # No Color

# Project variables
PROJECT_NAME := Tabi Backend
CLI := ./tabi

## Display help information
help:
	@echo "$(BLUE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║                    $(CYAN)🏠 Tabi Backend$(BLUE)                      ║$(NC)"
	@echo "$(BLUE)║                   $(YELLOW)Makefile Commands$(BLUE)                   ║$(NC)"
	@echo "$(BLUE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)🚀 Quick Commands:$(NC)"
	@echo "  $(GREEN)make dev$(NC)             - Start development environment"
	@echo "  $(GREEN)make init$(NC)            - Initialize project (first time)"
	@echo "  $(GREEN)make test$(NC)            - Run all tests"
	@echo "  $(GREEN)make clean$(NC)           - Clean everything"
	@echo ""
	@echo "$(CYAN)📦 Build & Deploy:$(NC)"
	@echo "  $(GREEN)make build$(NC)           - Build Docker image"
	@echo "  $(GREEN)make rebuild$(NC)         - Clean build"
	@echo "  $(GREEN)make start$(NC)           - Start application"
	@echo "  $(GREEN)make stop$(NC)            - Stop application"
	@echo "  $(GREEN)make restart$(NC)         - Restart application"
	@echo ""
	@echo "$(CYAN)📋 Monitoring:$(NC)"
	@echo "  $(GREEN)make status$(NC)          - Show system status"
	@echo "  $(GREEN)make logs$(NC)            - Show logs"
	@echo "  $(GREEN)make follow$(NC)          - Follow logs in real-time"
	@echo "  $(GREEN)make shell$(NC)           - Open container shell"
	@echo ""
	@echo "$(CYAN)🐳 Docker Compose:$(NC)"
	@echo "  $(GREEN)make up$(NC)              - Start with docker-compose"
	@echo "  $(GREEN)make down$(NC)            - Stop docker-compose services"
	@echo "  $(GREEN)make ps$(NC)              - Show running services"
	@echo ""
	@echo "$(CYAN)ℹ️  Information:$(NC)"
	@echo "  $(GREEN)make version$(NC)         - Show version information"
	@echo "  $(GREEN)make docs$(NC)            - Show documentation"
	@echo "  $(GREEN)make check$(NC)           - Check system dependencies"
	@echo ""
	@echo "$(YELLOW)💡 Tip: Run '$(GREEN)make dev$(NC)$(YELLOW)' to get started quickly!$(NC)"

## Initialize project (first-time setup)
init:
	@echo "$(BLUE)🚀 Initializing $(PROJECT_NAME)...$(NC)"
	$(CLI) init

## Start development environment
dev:
	@echo "$(BLUE)🛠️  Starting development environment...$(NC)"
	$(CLI) dev

## Build Docker image
build:
	@echo "$(BLUE)🔨 Building Docker image...$(NC)"
	$(CLI) build

## Clean build (rebuild from scratch)
rebuild:
	@echo "$(BLUE)🧹 Clean building Docker image...$(NC)"
	$(CLI) build --clean

## Start application
start:
	@echo "$(GREEN)▶️  Starting application...$(NC)"
	$(CLI) start

## Stop application
stop:
	@echo "$(RED)⏹️  Stopping application...$(NC)"
	$(CLI) stop

## Restart application
restart:
	@echo "$(YELLOW)🔄 Restarting application...$(NC)"
	$(CLI) restart

## Show system status
status:
	@echo "$(CYAN)📊 System Status:$(NC)"
	$(CLI) status

## Show logs
logs:
	@echo "$(CYAN)📋 Application Logs:$(NC)"
	$(CLI) logs

## Follow logs in real-time
follow:
	@echo "$(CYAN)📋 Following logs (Ctrl+C to stop)...$(NC)"
	$(CLI) logs -f

## Open container shell
shell:
	@echo "$(CYAN)💻 Opening container shell...$(NC)"
	$(CLI) shell

## Run tests
test:
	@echo "$(BLUE)🧪 Running tests...$(NC)"
	$(CLI) test

## Clean containers and images
clean:
	@echo "$(RED)🧹 Cleaning containers and images...$(NC)"
	$(CLI) clean

## Start with docker-compose
up:
	@echo "$(BLUE)🐳 Starting with Docker Compose...$(NC)"
	$(CLI) up

## Stop docker-compose services
down:
	@echo "$(RED)🐳 Stopping Docker Compose services...$(NC)"
	$(CLI) down

## Show running services
ps:
	@echo "$(CYAN)🐳 Running services:$(NC)"
	$(CLI) ps

## Setup MQTT authentication
setup-mqtt:
	@echo "$(BLUE)🔐 Setting up MQTT authentication...$(NC)"
	$(CLI) setup-mqtt

## Show version information
version:
	$(CLI) version

## Show documentation
docs:
	$(CLI) docs

## Check system dependencies
check:
	@echo "$(CYAN)🔍 Checking system dependencies...$(NC)"
	@command -v docker >/dev/null 2>&1 && echo "$(GREEN)✅ Docker: Available$(NC)" || echo "$(RED)❌ Docker: Missing$(NC)"
	@command -v docker-compose >/dev/null 2>&1 && echo "$(GREEN)✅ Docker Compose: Available$(NC)" || echo "$(RED)❌ Docker Compose: Missing$(NC)"
	@command -v curl >/dev/null 2>&1 && echo "$(GREEN)✅ curl: Available$(NC)" || echo "$(YELLOW)⚠️  curl: Missing (optional)$(NC)"
	@command -v jq >/dev/null 2>&1 && echo "$(GREEN)✅ jq: Available$(NC)" || echo "$(YELLOW)⚠️  jq: Missing (optional)$(NC)"
	@command -v mosquitto_pub >/dev/null 2>&1 && echo "$(GREEN)✅ Mosquitto clients: Available$(NC)" || echo "$(YELLOW)⚠️  Mosquitto clients: Missing (optional)$(NC)"

## Development workflow shortcuts
.PHONY: workflow quick-start full-clean

## Complete development workflow
workflow: clean build start status
	@echo "$(GREEN)✅ Development workflow complete!$(NC)"
	@echo "$(CYAN)💡 Run 'make follow' to watch logs$(NC)"

## Quick start (for daily development)
quick-start: build start
	@echo "$(GREEN)✅ Application started!$(NC)"
	@sleep 2
	@make status

## Full clean and restart
full-clean: down clean rebuild up
	@echo "$(GREEN)✅ Full clean and restart complete!$(NC)"

## Install development tools (optional)
install-tools:
	@echo "$(BLUE)🔧 Installing optional development tools...$(NC)"
	@echo "$(YELLOW)Installing mosquitto-clients...$(NC)"
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y mosquitto-clients jq; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install mosquitto jq; \
	elif command -v pacman >/dev/null 2>&1; then \
		sudo pacman -S mosquitto jq; \
	else \
		echo "$(YELLOW)⚠️  Please install mosquitto-clients and jq manually$(NC)"; \
	fi

## Show available API endpoints (when running)
api-help:
	@echo "$(CYAN)🌐 Available API Endpoints:$(NC)"
	@echo ""
	@echo "$(YELLOW)Health & Info:$(NC)"
	@echo "  GET  http://localhost:8080/hello-world"
	@echo "  GET  http://localhost:8080/blinds/status"
	@echo "  GET  http://localhost:8080/blinds/config"
	@echo "  GET  http://localhost:8080/blinds/rooms"
	@echo ""
	@echo "$(YELLOW)Control Commands:$(NC)"
	@echo "  POST http://localhost:8080/blinds/id/{blind_id}/{action}"
	@echo "  POST http://localhost:8080/blinds/room/{room}/{action}"
	@echo "  POST http://localhost:8080/blinds/all/{action}"
	@echo ""
	@echo "$(YELLOW)Actions: OPEN, CLOSE, STOP$(NC)"
	@echo ""
	@echo "$(CYAN)💡 Test with:$(NC)"
	@echo "  curl http://localhost:8080/blinds/status | jq"

## Quick API test
api-test:
	@echo "$(BLUE)🧪 Testing API endpoints...$(NC)"
	@curl -s http://localhost:8080/hello-world && echo ""
	@curl -s http://localhost:8080/blinds/status | jq . 2>/dev/null || curl -s http://localhost:8080/blinds/status
