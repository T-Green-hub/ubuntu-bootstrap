# Ubuntu Bootstrap - Makefile
# Convenience targets for ubuntu-bootstrap installation and management
#
# Quick Start:
#   make run        # Full bootstrap (base packages + hardware + verification)
#   make verify     # Verification only (fstrim, SMART, sensors, timer)
#   make devtools   # Install development tools only
#   make optional   # Show available optional features
#
# Quality & Testing:
#   make lint       # Full lint with shellcheck (requires shellcheck)
#   make lint-light # Fast syntax check (no dependencies required)
#   make detect     # Detect hardware and show recommendations
#   make check      # Check for deprecated packages
#
# Advanced:
#   make privacy-first  # Install privacy tools before dev tools
#   make ideal          # Complete setup with all features
#   make release TAG=vX.Y.Z  # Create git tag + GitHub release

SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -euo pipefail -c
# allow recipes to start with '>' instead of a literal TAB
.RECIPEPREFIX := >

DIR := $(shell cd $(dir $(lastword $(MAKEFILE_LIST))) && pwd)

.PHONY: run verify base optional detect check lint lint-light package release help ideal devtools privacy privacy-first

help: ## Show targets
> @grep -E '^[a-zA-Z_\-]+:.*?## ' Makefile | sed 's/:.*## / — /'

run: ## Base packages + verification
> "$(DIR)/scripts/run_bootstrap.sh"

verify: ## Only the verification (trim, SMART, sensors, timer)
> "$(DIR)/scripts/99_verify.sh"

base: ## Only the base package setup
> "$(DIR)/scripts/10_base-packages.sh"

optional: ## Install optional features (ProtonVPN, Brave, etc.)
> "$(DIR)/scripts/60_optional-features.sh"

detect: ## Run hardware detection and show recommendations
> "$(DIR)/scripts/detect_system.sh"

check: ## Check package compatibility for current Ubuntu version
> "$(DIR)/scripts/check_package_compat.sh" --known

lint: ## Lint scripts with shellcheck (requires shellcheck)
> @if ! command -v shellcheck >/dev/null 2>&1; then \
>   echo "shellcheck not found. Install: sudo apt install shellcheck"; \
>   exit 1; \
> fi
> shellcheck -x scripts/*.sh hardware/*.sh

lint-light: ## Fast syntax check (bash -n) for all scripts (no shellcheck needed)
> @echo "Running lightweight lint (bash -n)…"
> @rc=0; \
> for f in $$(git ls-files '*.sh'); do \
>   bash -n "$$f" || { echo "Syntax error in $$f"; rc=1; }; \
> done; \
> exit $$rc

devtools: ## Install development tools (Docker, Node, Python, Rust, Go, VS Code, utilities)
> "$(DIR)/scripts/40_dev-tools.sh"

privacy: ## Install privacy suite (ProtonVPN, Brave, TimeShift)
> "$(DIR)/scripts/60_optional-features.sh" protonvpn brave timeshift

privacy-first: ## Install privacy extras before dev tools (ProtonVPN, Brave, TimeShift → then Dev Tools)
> @echo "=== Installing Privacy & Productivity Suite FIRST ==="
> "$(DIR)/scripts/60_optional-features.sh" protonvpn brave timeshift || true
> @echo ""
> @echo "=== Installing Development Tools SECOND ==="
> "$(DIR)/scripts/40_dev-tools.sh" || true
> @echo ""
> @echo "=== Verifying Installation ==="
> "$(DIR)/scripts/99_verify.sh" || true
> @echo ""
> @echo "✓ Privacy-first setup complete!"

ideal: ## Complete ideal setup: dev tools + privacy suite + VLC + LibreOffice
> @echo "=== Installing Development Tools ==="
> "$(DIR)/scripts/40_dev-tools.sh" || true
> @echo ""
> @echo "=== Installing Privacy & Productivity Suite ==="
> "$(DIR)/scripts/60_optional-features.sh" protonvpn brave timeshift vlc libreoffice || true
> @echo ""
> @echo "=== Verifying Installation ==="
> "$(DIR)/scripts/99_verify.sh" || true
> @echo ""
> @echo "✓ Ideal setup complete!"
> @echo "  - ProtonVPN: protonvpn-app"
> @echo "  - TimeShift: sudo timeshift-gtk"
> @echo "  - Brave: brave-browser"
> @echo "  - Dev tools: docker, node, python, rust, go, code"
> @echo ""
> @echo "Next steps:"
> @echo "  1. Log out/in for Docker group membership"
> @echo "  2. Configure ProtonVPN auto-connect in app settings"
> @echo "  3. Create first TimeShift snapshot: sudo timeshift --create"

release: ## Tag + GitHub release. Usage: make release TAG=vX.Y.Z
> if [[ -z "$$TAG" ]]; then echo "Set TAG, e.g.: make release TAG=v0.1.2"; exit 1; fi
> git fetch --tags
> git tag -a "$$TAG" -m "$$TAG — bootstrap base+verify"
> git push origin "$$TAG"
> # Create package if present variables are set
> if [[ -f "ubuntu-bootstrap-$$TAG.tar.gz" ]]; then \
>   echo "Using existing package: ubuntu-bootstrap-$$TAG.tar.gz"; \
> else \
>   echo "Packaging repository for $$TAG…"; \
>   git archive -o "ubuntu-bootstrap-$$TAG.tar.gz" --format=tar.gz --prefix="ubuntu-bootstrap-$$TAG/" HEAD; \
>   sha256sum "ubuntu-bootstrap-$$TAG.tar.gz" | tee "ubuntu-bootstrap-$$TAG.tar.gz.sha256"; \
> fi
> # Create GitHub release and upload artifacts (requires gh auth)
> gh release create "$$TAG" \
>   "ubuntu-bootstrap-$$TAG.tar.gz" "ubuntu-bootstrap-$$TAG.tar.gz.sha256" \
>   --title "Ubuntu Bootstrap $$TAG" \
>   --notes-file RELEASE_NOTES.md
> echo "Release $$TAG published."

package: ## Build tar.gz + sha256 for a given TAG. Usage: make package TAG=vX.Y.Z
> if [[ -z "$$TAG" ]]; then echo "Set TAG, e.g.: make package TAG=v1.0.1"; exit 1; fi
> echo "Packaging repository for $$TAG…"
> git archive -o "ubuntu-bootstrap-$$TAG.tar.gz" --format=tar.gz --prefix="ubuntu-bootstrap-$$TAG/" HEAD
> sha256sum "ubuntu-bootstrap-$$TAG.tar.gz" | tee "ubuntu-bootstrap-$$TAG.tar.gz.sha256"
> ls -lh "ubuntu-bootstrap-$$TAG.tar.gz" "ubuntu-bootstrap-$$TAG.tar.gz.sha256"
