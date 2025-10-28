# Minimal convenience targets for ubuntu-bootstrap
# Usage:
#   make run        # base packages + verification
#   make verify     # verification only (fstrim, SMART, sensors, timer)
#   make base       # base packages only
#   make release TAG=v0.1.0  # create git tag + GitHub release

# IMPORTANT: SHELL must be a single path (no spaces). /bin/bash works everywhere on Ubuntu.
SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -euo pipefail -c
# allow recipes to start with '>' instead of a literal TAB
.RECIPEPREFIX := >

DIR := $(HOME)/code/ubuntu-bootstrap

.PHONY: run verify base release help

help: ## Show targets
> @grep -E '^[a-zA-Z_\-]+:.*?## ' Makefile | sed 's/:.*## / — /'

run: ## Base packages + verification
> "$(DIR)/scripts/run_bootstrap.sh"

verify: ## Only the verification (trim, SMART, sensors, timer)
> "$(DIR)/scripts/99_verify.sh"

base: ## Only the base package setup
> "$(DIR)/scripts/10_base-packages.sh"

release: ## Tag + GitHub release. Usage: make release TAG=vX.Y.Z
> if [[ -z "$$TAG" ]]; then echo "Set TAG, e.g.: make release TAG=v0.1.0"; exit 1; fi
> git fetch --tags
> git tag -a "$$TAG" -m "$$TAG — bootstrap base+verify"
> git push origin "$$TAG"
> gh release create "$$TAG" \
>   --title "$$TAG — bootstrap base+verify" \
>   --notes "Minimal, idempotent bootstrap for Ubuntu 24.04: base packages + verification. Tested $$(date +%Y-%m-%d) PT."
> echo "Release $$TAG published."
