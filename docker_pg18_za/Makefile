# Makefile for PostgreSQL 18 Docker Image
# Usage: make [target]

# Load environment variables from .env file
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# Configuration
DOCKER_CMD ?= docker
REGISTRY ?= docker.io
DOCKERHUB_USER ?= warkanum
IMAGE_NAME ?= postgresql18_za
FULL_IMAGE_NAME = $(REGISTRY)/$(DOCKERHUB_USER)/$(IMAGE_NAME)
VERSION ?= latest
CONTAINER_NAME ?= postgresql18_za

# Docker build arguments
DOCKER_UID ?= 1000
DOCKER_GID ?= 1000

# Container runtime settings
HOST_PORT ?= 5432
CONTAINER_PORT ?= 5432
DATA_DIR ?= /tmp/postgresql18_za_data
SHM_SIZE ?= 4g
MEMORY_LIMIT ?= 4G
CPU_LIMIT ?= 4

# Color output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

.PHONY: help build tag push push-skopeo login logout run stop restart clean logs shell all release

# Default target
help:
	@printf '%b\n' "$(BLUE)PostgreSQL 18 Docker Image - Available targets:$(NC)"
	@printf '%b\n' ""
	@printf '%b\n' "  $(GREEN)build$(NC)          - Build the Docker image"
	@printf '%b\n' "  $(GREEN)tag$(NC)            - Tag the image with version"
	@printf '%b\n' "  $(GREEN)push$(NC)           - Push the image to registry"
	@printf '%b\n' "  $(GREEN)login$(NC)          - Login to registry"
	@printf '%b\n' "  $(GREEN)logout$(NC)         - Logout from registry"
	@printf '%b\n' "  $(GREEN)run$(NC)            - Run the container"
	@printf '%b\n' "  $(GREEN)stop$(NC)           - Stop the container"
	@printf '%b\n' "  $(GREEN)restart$(NC)        - Restart the container"
	@printf '%b\n' "  $(GREEN)clean$(NC)          - Remove container and image"
	@printf '%b\n' "  $(GREEN)logs$(NC)           - Show container logs"
	@printf '%b\n' "  $(GREEN)shell$(NC)          - Open shell in running container"
	@printf '%b\n' "  $(GREEN)all$(NC)            - Build, tag, and push image"
	@printf '%b\n' ""
	@printf '%b\n' "$(YELLOW)Configuration:$(NC)"
	@printf '%b\n' "  Registry: $(REGISTRY)"
	@printf '%b\n' "  Image: $(FULL_IMAGE_NAME):$(VERSION)"
	@printf '%b\n' "  Container: $(CONTAINER_NAME)"
	@printf '%b\n' "  Port: $(HOST_PORT):$(CONTAINER_PORT)"
	@printf '%b\n' "  Data: $(DATA_DIR)"

# Build the Docker image
build:
	@printf '%b\n' "$(BLUE)Building Docker image: $(FULL_IMAGE_NAME)$(NC)"
	$(DOCKER_CMD) build \
		--build-arg DOCKER_UID=$(DOCKER_UID) \
		--build-arg DOCKER_GID=$(DOCKER_GID) \
		-t $(FULL_IMAGE_NAME):latest \
		.
	@printf '%b\n' "$(GREEN)Build complete!$(NC)"

# Tag the image with version
tag: build
	@printf '%b\n' "$(BLUE)Tagging image as $(VERSION)$(NC)"
	$(DOCKER_CMD) tag $(FULL_IMAGE_NAME):latest $(FULL_IMAGE_NAME):$(VERSION)
	@printf '%b\n' "$(GREEN)Tagged as $(FULL_IMAGE_NAME):$(VERSION)$(NC)"

# Login to registry
login:
	@printf '%b\n' "$(BLUE)Logging in to $(REGISTRY)...$(NC)"
	$(DOCKER_CMD) login $(REGISTRY)
	@printf '%b\n' "$(GREEN)Login successful!$(NC)"

# Logout from registry
logout:
	@printf '%b\n' "$(BLUE)Logging out from $(REGISTRY)...$(NC)"
	$(DOCKER_CMD) logout $(REGISTRY)
	@printf '%b\n' "$(GREEN)Logout successful!$(NC)"

# Push image to registry
push:
	@printf '%b\n' "$(BLUE)Pushing image to $(REGISTRY)...$(NC)"
	$(DOCKER_CMD) push $(FULL_IMAGE_NAME):latest
ifneq ($(VERSION),latest)
	$(DOCKER_CMD) push $(FULL_IMAGE_NAME):$(VERSION)
endif
	@printf '%b\n' "$(GREEN)Push complete!$(NC)"

# Push image via skopeo (fallback for podman auth scope bugs)
push-skopeo:
	@printf '%b\n' "$(BLUE)Pushing image to $(REGISTRY) via skopeo...$(NC)"
	skopeo copy containers-storage:$(FULL_IMAGE_NAME):latest docker://$(FULL_IMAGE_NAME):latest
ifneq ($(VERSION),latest)
	skopeo copy containers-storage:$(FULL_IMAGE_NAME):$(VERSION) docker://$(FULL_IMAGE_NAME):$(VERSION)
endif
	@printf '%b\n' "$(GREEN)Push complete!$(NC)"

# Prepare data directory
prepare-data-dir:
	@printf '%b\n' "$(BLUE)Preparing data directory...$(NC)"
	mkdir -p $(DATA_DIR)
	chmod 777 $(DATA_DIR)

# Stop and remove existing container
stop:
	@printf '%b\n' "$(BLUE)Stopping container: $(CONTAINER_NAME)$(NC)"
	-$(DOCKER_CMD) stop $(CONTAINER_NAME) 2>/dev/null || true
	-$(DOCKER_CMD) rm $(CONTAINER_NAME) 2>/dev/null || true
	@printf '%b\n' "$(GREEN)Container stopped and removed$(NC)"

# Run the container
run: prepare-data-dir stop
	@printf '%b\n' "$(BLUE)Starting container: $(CONTAINER_NAME)$(NC)"
	$(DOCKER_CMD) run -d \
		-p $(HOST_PORT):$(CONTAINER_PORT) \
		--shm-size=$(SHM_SIZE) \
		-v $(DATA_DIR):/var/lib/postgresql \
		--env-file ./.env \
		--name $(CONTAINER_NAME) \
		--restart unless-stopped \
		--memory=$(MEMORY_LIMIT) \
		--cpus=$(CPU_LIMIT) \
		$(FULL_IMAGE_NAME):latest
	@printf '%b\n' "$(GREEN)Container started: $(CONTAINER_NAME)$(NC)"
	@printf '%b\n' "$(YELLOW)Connect with: psql -h localhost -p $(HOST_PORT) -U $(POSTGRES_USER) -d $(POSTGRES_DB)$(NC)"

# Restart the container
restart: stop run

# Show container logs
logs:
	@printf '%b\n' "$(BLUE)Showing logs for: $(CONTAINER_NAME)$(NC)"
	$(DOCKER_CMD) logs -f $(CONTAINER_NAME)

# Open shell in container
shell:
	@printf '%b\n' "$(BLUE)Opening shell in: $(CONTAINER_NAME)$(NC)"
	$(DOCKER_CMD) exec -it $(CONTAINER_NAME) /bin/sh

# Clean up container and images
clean: stop
	@printf '%b\n' "$(BLUE)Removing images...$(NC)"
	-$(DOCKER_CMD) rmi $(FULL_IMAGE_NAME):latest 2>/dev/null || true
ifneq ($(VERSION),latest)
	-$(DOCKER_CMD) rmi $(FULL_IMAGE_NAME):$(VERSION) 2>/dev/null || true
endif
	@printf '%b\n' "$(GREEN)Cleanup complete!$(NC)"

# Build, tag, and push
all: build tag push
	@printf '%b\n' "$(GREEN)All tasks complete!$(NC)"

# Release: git tag and push tag
release:
ifeq ($(VERSION),latest)
	@printf '%b\n' "$(YELLOW)ERROR: Set VERSION to create a release (e.g. make release VERSION=1.0.0)$(NC)"
	@exit 1
endif
	@printf '%b\n' "$(BLUE)Creating git tag v$(VERSION)...$(NC)"
	git tag -a v$(VERSION) -m "Release v$(VERSION)"
	git push origin v$(VERSION)
	@printf '%b\n' "$(GREEN)Released v$(VERSION)$(NC)"

# Show current status
status:
	@printf '%b\n' "$(BLUE)Docker Images:$(NC)"
	@$(DOCKER_CMD) images | grep $(IMAGE_NAME) || echo "No images found"
	@printf '%b\n' ""
	@printf '%b\n' "$(BLUE)Running Containers:$(NC)"
	@$(DOCKER_CMD) ps -a | grep $(CONTAINER_NAME) || echo "No containers found"
