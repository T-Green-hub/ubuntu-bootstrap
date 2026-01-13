# Ubuntu Bootstrap - AI Agent Instructions

## Project Overview
Ubuntu Bootstrap is a **production-ready system automation toolkit** for Ubuntu 24.04 LTS (Noble). It's not a toy script—it's a **battle-tested, hardware-aware bootstrap** used in CI/CD and on real ThinkPad/HP laptops. The codebase prioritizes **safety, idempotency, and evidence-based execution**.

**Current version:** v4.0.6 (maintained in [scripts/lib/version.sh](../scripts/lib/version.sh))

## Core Architecture

### 1. Three-Layer Design
```
scripts/bootstrap.sh          # Main orchestrator (profiles: minimal/dev/secure)
├── scripts/lib/*.sh          # Shared libraries (logging, detection, privileged wrapper)
├── hardware/*.sh             # Hardware-specific optimizations (ThinkPad, HP, generic)
└── scripts/dev-modules/*.sh  # Optional dev tools (docker, nodejs, python, rust, go, vscode)
```

### 2. Privileged Operations Safety (`scripts/lib/privileged.sh`)
**Critical rule:** In `DRY_RUN=1` or CI mode, `run_privileged()` **never calls sudo**. All privileged commands go through this wrapper:
```bash
run_privileged apt-get update  # Respects DRY_RUN/CI_MODE
run_sudo ufw enable            # Legacy wrapper, being phased out
```

### 3. Profile System
Three built-in profiles in `bootstrap.sh`:
- `minimal`: Base packages + firmware + privacy settings
- `dev`: Minimal + build-essential + python/node/git
- `secure`: Minimal + UFW firewall + fail2ban + auditd

**How to add profile logic:**
```bash
if [[ "$PROFILE" == "dev" ]]; then
    apt_install nodejs npm
fi
```

## Critical Workflows

### Building/Testing
```bash
# Syntax validation (required before commits)
bash -n scripts/bootstrap.sh scripts/checks/bootstrap_check.sh scripts/lib/*.sh

# Dry-run (shows plan without system changes)
bash scripts/bootstrap.sh --profile minimal --dry-run

# Health check (read-only, no sudo required)
bash scripts/checks/bootstrap_check.sh

# CI-safe execution (used in GitHub Actions)
bash scripts/bootstrap.sh --ci --profile minimal
```

### Adding New Features
1. **New dev module?** → Create `scripts/dev-modules/myfeature.sh` following the pattern in `docker.sh`
2. **New hardware profile?** → Add to `hardware/` and import in `bootstrap.sh`
3. **Modify core logic?** → Update `bootstrap.sh` and ensure `DRY_RUN=1` produces correct output

## Project-Specific Conventions

### Logging
Always use the logging library (sourced from `scripts/lib/logging.sh`):
```bash
log_info "Starting process..."    # Blue info icon
log_success "Install complete"    # Green checkmark
log_warning "Package not found"   # Yellow warning
log_error "Failed to connect"     # Red error (stderr)
log_step "A. System Setup"        # Cyan section header
```

### Error Handling
Scripts use `set -euo pipefail` by default. Exceptions:
- Commands expected to fail: `|| true` suffix
- Optional operations: `if command -v tool; then ... fi`
- Privileged ops in dry-run: `if ! privileged_allowed; then log_info "Skipped"; return 0; fi`

### Idempotency
Every function must be safe to run multiple times:
```bash
# Good: Check before install
if ! command -v docker >/dev/null 2>&1; then
    apt_install docker-ce
fi

# Bad: Blindly appending to config files without checking
echo "option=value" >> ~/.bashrc  # Will duplicate on re-run!
```

### Hardware Detection
Use detection library functions (from `scripts/lib/detection.sh`):
```bash
if is_laptop; then
    apt_install tlp
fi

if has_nvidia_gpu; then
    apt_install nvidia-driver-535
fi
```

## Integration Points

### APT Lock Handling
Ubuntu's unattended-upgrades can block apt operations. All scripts must:
```bash
source "${SCRIPT_DIR}/../hardware/common.sh"  # Provides wait_for_dpkg_lock()
wait_for_dpkg_lock 180  # Wait up to 180s for locks to clear
```

### Dev Modules Pattern
Each module in `scripts/dev-modules/` follows this structure:
1. `install_X()` - Main installation function
2. `is_X_installed()` - Check if already present
3. `test_X()` - Verify installation works
4. Standalone executable: `bash scripts/dev-modules/docker.sh` works independently

Example from `docker.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

install_docker() {
    if command -v docker >/dev/null 2>&1; then
        log "Docker already installed"
        return 0
    fi
    # Install logic...
}

# Allow sourcing OR direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_docker "$@"
fi
```

### CI Integration
GitHub Actions workflow (`.github/workflows/ci.yml`) runs:
- `shellcheck` on all `.sh` files (warnings allowed, errors fail)
- `bash -n` syntax validation (must pass)
- Dry-run tests with `--ci` flag (no sudo prompts)

## Key Files Reference

- [scripts/bootstrap.sh](../scripts/bootstrap.sh) - Main entry point, orchestrates all steps
- [scripts/checks/bootstrap_check.sh](../scripts/checks/bootstrap_check.sh) - Read-only health checker
- [scripts/lib/version.sh](../scripts/lib/version.sh) - **Single source of truth** for version strings
- [scripts/lib/privileged.sh](../scripts/lib/privileged.sh) - Dry-run/CI-safe sudo wrapper
- [scripts/lib/logging.sh](../scripts/lib/logging.sh) - Colored timestamped logging
- [scripts/lib/package.sh](../scripts/lib/package.sh) - Safe apt operations with lock handling
- [Makefile](../Makefile) - Convenient targets (`make bootstrap`, `make lint`)
- [docs/MASTER_PROMPT_V4_0_6.md](../docs/MASTER_PROMPT_V4_0_6.md) - Detailed AI agent workflow

## Common Pitfalls

1. **Don't bypass privileged wrapper:** Use `run_privileged` instead of raw `sudo` in new code
2. **Don't forget DRY_RUN guards:** New functions that modify system state must check `(( DRY_RUN == 1 ))`
3. **Don't assume packages exist:** Use `command -v tool || apt_install package` pattern
4. **Version sync:** After bumping `BOOTSTRAP_VERSION` in `version.sh`, verify both `bootstrap.sh` and `bootstrap_check.sh` report same version

## Testing Commands
```bash
# Quick syntax check (no shellcheck needed)
make lint-light

# Full shellcheck linting
make lint

# Format shell scripts
make fmt

# Dry-run minimal profile (safe, no changes)
make bootstrap

# Health check current system
make bootstrap-check
```

## Evidence-Based Changes
When modifying core bootstrap logic:
1. Run `bash -n` to validate syntax
2. Test in dry-run: `bash scripts/bootstrap.sh --profile minimal --dry-run`
3. Capture output: `bash scripts/bootstrap.sh --dry-run 2>&1 | tee test-output.txt`
4. Verify no sudo prompts appear in dry-run mode
5. Document changes in commit message with before/after behavior

## Code Style
- **Indentation:** 4 spaces (enforced by `shfmt -i 4`)
- **Variable naming:** `UPPERCASE_CONSTANTS`, `lowercase_functions`
- **Quotes:** Always quote variables: `"$VAR"` not `$VAR`
- **Conditionals:** Use `[[` not `[` for modern bash tests
- **Arrays:** Use bash arrays for lists, not space-separated strings
