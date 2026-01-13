# Minimal convenience targets for ubuntu-bootstrap
# Usage:
#   make run        # full bootstrap (base packages + hardware + verification)
#   make verify     # verification only (fstrim, SMART, sensors, timer)
#   make base       # base packages only
#   make lint       # lint scripts with shellcheck (requires shellcheck installed)
#   make release TAG=v0.2.0  # create git tag + GitHub release

SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -euo pipefail -c
# allow recipes to start with '>' instead of a literal TAB
.RECIPEPREFIX := >

DIR := $(shell cd $(dir $(lastword $(MAKEFILE_LIST))) && pwd)

.PHONY: run verify base optional detect check lint lint-light package release help ideal devtools privacy privacy-first menu preflight t14s-fixes bootstrap bootstrap-check test test-quick test-dry-run fmt

help: ## Show targets
> @grep -E '^[a-zA-Z_\\-]+:.*?## ' Makefile | sed 's/:.*## / — /'

# === New v4 Bootstrap Targets ===

bootstrap: ## Run new v4 bootstrap (minimal profile, dry-run mode - SAFE)
> bash "$(DIR)/scripts/bootstrap.sh" --profile minimal --dry-run

bootstrap-apply-minimal: ## APPLY minimal profile (make changes for real)
> bash "$(DIR)/scripts/bootstrap.sh" --profile minimal --yes

bootstrap-apply-dev: ## APPLY dev profile (make changes for real)
> bash "$(DIR)/scripts/bootstrap.sh" --profile dev --yes

bootstrap-apply-secure: ## APPLY secure profile (make changes for real)
> bash "$(DIR)/scripts/bootstrap.sh" --profile secure --yes

bootstrap-check: ## Run new v4 health checker
> bash "$(DIR)/scripts/checks/bootstrap_check.sh"

bootstrap-check-doctor: ## Run health checker in doctor mode
> bash "$(DIR)/scripts/checks/bootstrap_check.sh" --doctor

bootstrap-dev: ## Run new v4 bootstrap (dev profile, dry-run mode - SAFE)
> bash "$(DIR)/scripts/bootstrap.sh" --profile dev --dry-run

bootstrap-secure: ## Run new v4 bootstrap (secure profile, dry-run mode - SAFE)
> bash "$(DIR)/scripts/bootstrap.sh" --profile secure --dry-run

# === Legacy Targets ===

menu: ## Interactive menu (user-friendly guided setup)
> "$(DIR)/scripts/interactive_menu.sh"

preflight: ## Pre-flight system check (verify readiness)
> "$(DIR)/scripts/preflight_check.sh"

t14s-fixes: ## ThinkPad T14s Gen 2 specific fixes
> "$(DIR)/scripts/fix_t14s_gen2.sh"

run: ## Legacy: Base packages + verification (use 'make bootstrap' instead)
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
> @echo "Linting with shellcheck..."
> @shellcheck -x scripts/*.sh scripts/lib/*.sh scripts/checks/*.sh hardware/*.sh || true

lint-light: ## Fast syntax check (bash -n) for all scripts (no shellcheck needed)
> @echo "Running lightweight lint (bash -n)…"
> @rc=0; \
> for f in $$(git ls-files '*.sh'); do \
>   bash -n "$$f" || { echo "Syntax error in $$f"; rc=1; }; \
> done; \
> exit $$rc

fmt: ## Format shell scripts with shfmt (if available)
> @if command -v shfmt >/dev/null 2>&1; then \
>   echo "Formatting with shfmt..."; \
>   shfmt -w -i 4 -bn -ci scripts/*.sh scripts/lib/*.sh scripts/checks/*.sh hardware/*.sh; \
>   echo "Done!"; \
> else \
>   echo "shfmt not found. Install: sudo snap install shfmt or go install mvdan.cc/sh/v3/cmd/shfmt@latest"; \
> fi

test: ## Run full test suite for all modules
> @echo "Running full test suite..."
> bash "$(DIR)/scripts/tests/self_test.sh"

doctor: ## Run doctor checks (bootstrap + health checker)
> @echo "Running doctor checks..."
> bash "$(DIR)/scripts/bootstrap.sh" --doctor
> bash "$(DIR)/scripts/checks/bootstrap_check.sh" --doctor

install-cli: ## Install ubuntu-bootstrap CLI to ~/.local/bin
> bash "$(DIR)/scripts/install.sh"

uninstall-cli: ## Uninstall ubuntu-bootstrap CLI
> bash "$(DIR)/scripts/install.sh" --uninstall
> @rc=0; \
> for f in scripts/dev-modules/test_*.sh scripts/optional-features/test_*.sh; do \
>   if [ -f "$$f" ]; then \
>     echo ""; \
>     echo "Running: $$f"; \
>     bash "$$f" || rc=1; \
>   fi; \
> done; \
> if [ $$rc -eq 0 ]; then \
>   echo ""; \
>   echo "✓ All tests passed!"; \
> else \
>   echo ""; \
>   echo "✗ Some tests failed!"; \
>   exit 1; \
> fi

test-quick: ## Run quick smoke tests only
> @echo "Running v4 bootstrap in dry-run mode..."
> bash scripts/bootstrap.sh --profile minimal --dry-run
> @echo ""
> bash scripts/bootstrap.sh --profile dev --dry-run
> @echo ""
> @echo "Testing legacy scripts in DRY_RUN mode..."
> DRY_RUN=1 bash scripts/run_bootstrap.sh
> done
> @echo "✓ Quick tests passed!"

test-dry-run: ## Test all scripts in DRY_RUN mode
> @echo "Testing DRY_RUN mode for bootstrap..."
> DRY_RUN=1 bash scripts/run_bootstrap.sh
> @echo ""
> @echo "Testing DRY_RUN mode for optional features..."
> DRY_RUN=1 bash scripts/60_optional-features.sh protonvpn || true
> DRY_RUN=1 bash scripts/60_optional-features.sh brave || true
> @echo ""
> @echo "✓ DRY_RUN tests passed!"

test-syntax: ## Fast syntax validation for all shell scripts
> @echo "Checking syntax of all shell scripts..."
> @rc=0; \
> for f in $$(find . -name '*.sh' -type f); do \
>   bash -n "$$f" || { echo "Syntax error in $$f"; rc=1; }; \
> done; \
> if [ $$rc -eq 0 ]; then \
>   echo "✓ All scripts have valid syntax"; \
> else \
>   echo "✗ Syntax errors found"; \
>   exit 1; \
> fi

test-module: ## Test specific module. Usage: make test-module MODULE=utilities
> @if [ -z "$(MODULE)" ]; then \
>   echo "ERROR: MODULE not specified. Usage: make test-module MODULE=utilities"; \
>   exit 1; \
> fi
> @if [ -f "scripts/dev-modules/test_$(MODULE).sh" ]; then \
>   bash "scripts/dev-modules/test_$(MODULE).sh"; \
> elif [ -f "scripts/optional-features/test_$(MODULE).sh" ]; then \
>   bash "scripts/optional-features/test_$(MODULE).sh"; \
> else \
>   echo "ERROR: Test file not found for module: $(MODULE)"; \
>   echo "Available modules:"; \
>   for f in scripts/dev-modules/test_*.sh scripts/optional-features/test_*.sh; do \
>     if [ -f "$$f" ]; then \
>       echo "  - $$(basename $$f | sed 's/test_//' | sed 's/.sh//')"; \
>     fi; \
>   done; \
>   exit 1; \
> fi

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
