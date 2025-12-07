# Home Lab Makefile
# GNU-style variables with XDG-compliant defaults
#
# Usage:
#   make init     - Bootstrap Incus (install, configure, create project)
#   make backup   - Backup data to Recovery drive
#   make restore  - Restore data from Recovery drive
#   make help     - Show all targets

#=============================================================================
# Variables
#=============================================================================

# ANCHOR: paths
# XDG Base Directory defaults
XDG_DATA_HOME   ?= $(HOME)/.local/share
XDG_CONFIG_HOME ?= $(HOME)/.config
XDG_CACHE_HOME  ?= $(HOME)/.cache

# Incus-specific paths
INCUS_DATA_DIR  ?= $(XDG_DATA_HOME)/incus
INCUS_PROJECT   ?= homelab

# Removable media (udisks2 default: /media/$USER)
MEDIA_DIR       ?= /media/$(USER)
RECOVERY_DIR    ?= $(MEDIA_DIR)/Recovery
BACKUP_DIR      ?= $(RECOVERY_DIR)/backups
# ANCHOR_END: paths

# Zabbly GPG key fingerprint (for verification)
ZABBLY_FINGERPRINT := 4EFC590696CB15B87C73A3AD82CC8797C838DCFD

# Colors for output
BLUE  := \033[34m
GREEN := \033[32m
YELLOW := \033[33m
RED   := \033[31m
RESET := \033[0m

#=============================================================================
# Main targets
#=============================================================================

.PHONY: help init backup restore status docs docs-serve

help: ## Show this help
	@echo "Home Lab Management"
	@echo ""
	@echo "Usage: make [target] [VAR=value]"
	@echo ""
	@echo "Variables:"
	@echo "  INCUS_DATA_DIR  Data directory (default: $(INCUS_DATA_DIR))"
	@echo "  INCUS_PROJECT   Target project (default: $(INCUS_PROJECT))"
	@echo "  RECOVERY_DIR    Recovery drive (default: $(RECOVERY_DIR))"
	@echo "  BACKUP_DIR      Backup location (default: $(BACKUP_DIR))"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-20s$(RESET) %s\n", $$1, $$2}'

init: install-incus configure-incus setup-defaults create-project setup-profiles ## Bootstrap Incus from scratch
	@incus project switch $(INCUS_PROJECT)
	@echo ""
	@echo "$(GREEN)Initialization complete!$(RESET)"
	@echo ""
	@echo "Next steps:"
	@echo "  - Access web UI: https://localhost:8443"
	@echo "  - Check status:  make status"

#=============================================================================
# Incus installation
#=============================================================================

.PHONY: install-incus configure-incus

install-incus: ## Install Incus from Zabbly repository
	@if command -v incus >/dev/null 2>&1; then \
		echo "$(GREEN)Incus already installed:$(RESET) $$(incus --version)"; \
	else \
		echo "$(GREEN)Installing Incus from Zabbly stable repository...$(RESET)"; \
		sudo mkdir -p /etc/apt/keyrings/; \
		curl -fsSL https://pkgs.zabbly.com/key.asc | sudo tee /etc/apt/keyrings/zabbly.asc > /dev/null; \
		echo "$(GREEN)Verifying GPG key fingerprint...$(RESET)"; \
		FINGERPRINT=$$(gpg --show-keys --fingerprint /etc/apt/keyrings/zabbly.asc 2>/dev/null | grep -oP '[A-F0-9 ]{40,}' | tr -d ' ' | head -1); \
		if [ "$$FINGERPRINT" != "$(ZABBLY_FINGERPRINT)" ]; then \
			echo "$(RED)GPG key fingerprint mismatch!$(RESET)"; \
			echo "Expected: $(ZABBLY_FINGERPRINT)"; \
			echo "Got: $$FINGERPRINT"; \
			exit 1; \
		fi; \
		echo "$(GREEN)Adding Zabbly apt repository...$(RESET)"; \
		. /etc/os-release && printf '%s\n' \
			"Enabled: yes" \
			"Types: deb" \
			"URIs: https://pkgs.zabbly.com/incus/stable" \
			"Suites: $$VERSION_CODENAME" \
			"Components: main" \
			"Architectures: $$(dpkg --print-architecture)" \
			"Signed-By: /etc/apt/keyrings/zabbly.asc" \
			| sudo tee /etc/apt/sources.list.d/zabbly-incus-stable.sources > /dev/null; \
		sudo apt-get update; \
		sudo apt-get install -y incus incus-ui-canonical; \
		echo "$(GREEN)Incus installed successfully$(RESET)"; \
	fi

configure-incus: ## Configure Incus (enable web UI)
	@if sudo incus config get core.https_address >/dev/null 2>&1 && \
	    [ -n "$$(sudo incus config get core.https_address)" ]; then \
		echo "$(GREEN)Incus web UI already configured$(RESET)"; \
	else \
		echo "$(GREEN)Enabling Incus web UI on port 8443...$(RESET)"; \
		sudo incus config set core.https_address :8443; \
	fi

setup-defaults: ## Create default storage pool and network
	@if incus storage show default >/dev/null 2>&1; then \
		echo "$(GREEN)Storage pool 'default' already exists$(RESET)"; \
	else \
		echo "$(GREEN)Creating default storage pool...$(RESET)"; \
		incus storage create default dir; \
	fi
	@if incus network show incusbr0 >/dev/null 2>&1; then \
		echo "$(GREEN)Network 'incusbr0' already exists$(RESET)"; \
	else \
		echo "$(GREEN)Creating default network...$(RESET)"; \
		incus network create incusbr0; \
	fi

#=============================================================================
# Project and profile setup
#=============================================================================

.PHONY: create-project setup-profiles setup-defaults

create-project: ## Create homelab project with restrictions
	@if incus project show $(INCUS_PROJECT) >/dev/null 2>&1; then \
		echo "$(GREEN)Project $(INCUS_PROJECT) already exists$(RESET)"; \
	else \
		echo "$(GREEN)Creating project: $(INCUS_PROJECT)$(RESET)"; \
		incus project create $(INCUS_PROJECT); \
	fi
	@echo "$(GREEN)Configuring project restrictions...$(RESET)"
# ANCHOR: project-config
	@incus project set $(INCUS_PROJECT) restricted=true
	@incus project set $(INCUS_PROJECT) features.images=true
	@incus project set $(INCUS_PROJECT) features.profiles=true
	@incus project set $(INCUS_PROJECT) features.storage.volumes=true
	@incus project set $(INCUS_PROJECT) restricted.devices.disk=allow
	@incus project set $(INCUS_PROJECT) restricted.devices.disk.paths="$(HOME),$(RECOVERY_DIR)"
	@incus project set $(INCUS_PROJECT) restricted.devices.usb=allow
	@incus project set $(INCUS_PROJECT) restricted.containers.nesting=allow
	@incus project set $(INCUS_PROJECT) restricted.idmap.uid=1000
	@incus project set $(INCUS_PROJECT) restricted.idmap.gid=1000
# ANCHOR_END: project-config

setup-profiles: ## Import all profiles from incus/profiles/
	@echo "$(GREEN)Importing profiles for $(INCUS_PROJECT)...$(RESET)"
	@for file in incus/profiles/*.yaml; do \
		name=$$(basename "$$file" .yaml); \
		if [ "$$name" = "homelab-default" ]; then \
			target="default"; \
		else \
			target="$$name"; \
		fi; \
		if ! incus profile show "$$target" --project $(INCUS_PROJECT) >/dev/null 2>&1; then \
			echo "  Creating profile: $$target"; \
			incus profile create "$$target" --project $(INCUS_PROJECT); \
		fi; \
		echo "  Applying: $$file -> $$target"; \
		incus profile edit "$$target" --project $(INCUS_PROJECT) < "$$file"; \
	done

#=============================================================================
# Backup and restore
#=============================================================================

.PHONY: backup restore

backup: ## Backup INCUS_DATA_DIR to Recovery drive
	@echo "$(GREEN)Backing up to $(BACKUP_DIR)/incus/...$(RESET)"
	@mkdir -p "$(BACKUP_DIR)/incus"
	@if [ -d "$(INCUS_DATA_DIR)" ]; then \
		rsync -av --delete "$(INCUS_DATA_DIR)/" "$(BACKUP_DIR)/incus/"; \
		echo "$(GREEN)Backup complete$(RESET)"; \
	else \
		echo "$(YELLOW)Nothing to backup - $(INCUS_DATA_DIR) does not exist$(RESET)"; \
	fi

restore: ## Restore from Recovery drive to INCUS_DATA_DIR
	@echo "$(GREEN)Restoring from $(BACKUP_DIR)/incus/...$(RESET)"
	@if [ -d "$(BACKUP_DIR)/incus" ]; then \
		mkdir -p "$(INCUS_DATA_DIR)"; \
		rsync -av "$(BACKUP_DIR)/incus/" "$(INCUS_DATA_DIR)/"; \
		echo "$(GREEN)Restore complete$(RESET)"; \
	else \
		echo "$(RED)Backup not found at $(BACKUP_DIR)/incus$(RESET)"; \
		exit 1; \
	fi

#=============================================================================
# Status and verification
#=============================================================================

.PHONY: status

status: ## Show status of Incus projects and instances
	@echo "$(GREEN)Projects:$(RESET)"
	@incus project list 2>/dev/null || echo "  (Incus not available)"
	@echo ""
	@echo "$(GREEN)Instances in $(INCUS_PROJECT):$(RESET)"
	@incus list --project $(INCUS_PROJECT) 2>/dev/null || echo "  (project not available)"

#=============================================================================
# Documentation
#=============================================================================

.PHONY: docs docs-serve

docs: ## Build documentation
	cd docs && mdbook build

docs-serve: ## Serve documentation locally
	cd docs && mdbook serve --open
