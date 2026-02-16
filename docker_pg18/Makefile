# Makefile for PostgreSQL 18 Docker Image
# Usage: make [target]

# Load environment variables from .env file
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# Configuration
DOCKERHUB_USER ?= warkypublic
IMAGE_NAME ?= pgsql18
FULL_IMAGE_NAME = $(DOCKERHUB_USER)/$(IMAGE_NAME)
VERSION ?= latest
CONTAINER_NAME ?= pgsql18

# Docker build arguments
DOCKER_UID ?= 1000
DOCKER_GID ?= 1000

# Container runtime settings
HOST_PORT ?= 5432
CONTAINER_PORT ?= 5432
DATA_DIR ?= /tmp/pgsql18_data
SHM_SIZE ?= 4g
MEMORY_LIMIT ?= 4G
CPU_LIMIT ?= 4

# Color output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

.PHONY: help build tag push login logout run stop restart clean logs shell all

# Default target
help:
	@echo "$(BLUE)PostgreSQL 18 Docker Image - Available targets:$(NC)"
	@echo ""
	@echo "  $(GREEN)build$(NC)          - Build the Docker image"
	@echo "  $(GREEN)tag$(NC)            - Tag the image with version"
	@echo "  $(GREEN)push$(NC)           - Push the image to DockerHub"
	@echo "  $(GREEN)login$(NC)          - Login to DockerHub"
	@echo "  $(GREEN)logout$(NC)         - Logout from DockerHub"
	@echo "  $(GREEN)run$(NC)            - Run the container"
	@echo "  $(GREEN)stop$(NC)           - Stop the container"
	@echo "  $(GREEN)restart$(NC)        - Restart the container"
	@echo "  $(GREEN)clean$(NC)          - Remove container and image"
	@echo "  $(GREEN)logs$(NC)           - Show container logs"
	@echo "  $(GREEN)shell$(NC)          - Open shell in running container"
	@echo "  $(GREEN)all$(NC)            - Build, tag, and push image"
	@echo ""
	@echo "$(YELLOW)Configuration:$(NC)"
	@echo "  Image: $(FULL_IMAGE_NAME):$(VERSION)"
	@echo "  Container: $(CONTAINER_NAME)"
	@echo "  Port: $(HOST_PORT):$(CONTAINER_PORT)"
	@echo "  Data: $(DATA_DIR)"

# Build the Docker image
build:
	@echo "$(BLUE)Building Docker image: $(FULL_IMAGE_NAME)$(NC)"
	docker build \
		--build-arg DOCKER_UID=$(DOCKER_UID) \
		--build-arg DOCKER_GID=$(DOCKER_GID) \
		-t $(FULL_IMAGE_NAME):latest \
		.
	@echo "$(GREEN)Build complete!$(NC)"

# Tag the image with version
tag: build
	@echo "$(BLUE)Tagging image as $(VERSION)$(NC)"
	docker tag $(FULL_IMAGE_NAME):latest $(FULL_IMAGE_NAME):$(VERSION)
	@echo "$(GREEN)Tagged as $(FULL_IMAGE_NAME):$(VERSION)$(NC)"

# Login to DockerHub
login:
	@echo "$(BLUE)Logging in to DockerHub...$(NC)"
	docker login
	@echo "$(GREEN)Login successful!$(NC)"

# Logout from DockerHub
logout:
	@echo "$(BLUE)Logging out from DockerHub...$(NC)"
	docker logout
	@echo "$(GREEN)Logout successful!$(NC)"

# Push image to DockerHub
push:
	@echo "$(BLUE)Pushing image to DockerHub...$(NC)"
	docker push $(FULL_IMAGE_NAME):latest
ifneq ($(VERSION),latest)
	docker push $(FULL_IMAGE_NAME):$(VERSION)
endif
	@echo "$(GREEN)Push complete!$(NC)"

# Prepare data directory
prepare-data-dir:
	@echo "$(BLUE)Preparing data directory...$(NC)"
	mkdir -p $(DATA_DIR)
	chmod 777 $(DATA_DIR)

# Stop and remove existing container
stop:
	@echo "$(BLUE)Stopping container: $(CONTAINER_NAME)$(NC)"
	-docker stop $(CONTAINER_NAME) 2>/dev/null || true
	-docker rm $(CONTAINER_NAME) 2>/dev/null || true
	@echo "$(GREEN)Container stopped and removed$(NC)"

# Run the container
run: prepare-data-dir stop
	@echo "$(BLUE)Starting container: $(CONTAINER_NAME)$(NC)"
	docker run -d \
		-p $(HOST_PORT):$(CONTAINER_PORT) \
		--shm-size=$(SHM_SIZE) \
		-v $(DATA_DIR):/var/lib/postgresql \
		--env-file ./.env \
		--name $(CONTAINER_NAME) \
		--restart unless-stopped \
		--memory=$(MEMORY_LIMIT) \
		--cpus=$(CPU_LIMIT) \
		$(FULL_IMAGE_NAME):latest
	@echo "$(GREEN)Container started: $(CONTAINER_NAME)$(NC)"
	@echo "$(YELLOW)Connect with: psql -h localhost -p $(HOST_PORT) -U postgres$(NC)"

# Restart the container
restart: stop run

# Show container logs
logs:
	@echo "$(BLUE)Showing logs for: $(CONTAINER_NAME)$(NC)"
	docker logs -f $(CONTAINER_NAME)

# Open shell in container
shell:
	@echo "$(BLUE)Opening shell in: $(CONTAINER_NAME)$(NC)"
	docker exec -it $(CONTAINER_NAME) /bin/sh

# Clean up container and images
clean: stop
	@echo "$(BLUE)Removing images...$(NC)"
	-docker rmi $(FULL_IMAGE_NAME):latest 2>/dev/null || true
ifneq ($(VERSION),latest)
	-docker rmi $(FULL_IMAGE_NAME):$(VERSION) 2>/dev/null || true
endif
	@echo "$(GREEN)Cleanup complete!$(NC)"

# Build, tag, and push
all: build tag push
	@echo "$(GREEN)All tasks complete!$(NC)"

# Show current status
status:
	@echo "$(BLUE)Docker Images:$(NC)"
	@docker images | grep $(IMAGE_NAME) || echo "No images found"
	@echo ""
	@echo "$(BLUE)Running Containers:$(NC)"
	@docker ps -a | grep $(CONTAINER_NAME) || echo "No containers found"
