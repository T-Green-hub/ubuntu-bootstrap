# Changelog

All notable changes to the Ubuntu Bootstrap project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.1.0] - 2026-01-13

### 🌟 Master Prompt Alignment Release
This release achieves 100% compliance with the Agent Mode Master Prompt (2025), adding comprehensive support for virtualization, remote access, containerization templates, and user feedback.

### Added
- **Virtual Machine Management** (`scripts/optional-features/virtualization.sh`)
  - VirtualBox installation with Extension Pack
  - QEMU/KVM setup with libvirt and virt-manager
  - Interactive hypervisor selection
  - Automatic user group management

- **Remote Tools Suite** (`scripts/optional-features/remote_tools.sh`)
  - OpenSSH Server installation with UFW integration
  - Remmina remote desktop client with RDP/VNC/SPICE plugins
  - Interactive tool selection

- **User Feedback System** (`scripts/optional-features/feedback.sh`)
  - Post-installation satisfaction ratings (1-5 scale)
  - CSV logging to `bootstrap-logs/feedback.csv`
  - Interactive comment collection

- **Docker Enhancements** (`scripts/dev-modules/docker.sh`)
  - Standalone execution mode
  - `--templates` flag for docker-compose templates
  - Pre-configured templates for Nginx, Redis, and MySQL
  - Improved error handling and dry-run support

### Changed
- **Version** bumped from 4.0.7 → 4.1.0
- **Docker Module** completely rewritten for better modularity
- **Makefile** updated with new test targets (`test-v4`, `test-modules`, `test-all`)
- **Test Suite** comprehensive v4.1.0 test suite created (`scripts/tests/test_v4_1_0.sh`)

### Documentation
- Created `docs/PRODUCTION_READINESS_v4_1_0.md` - Production deployment checklist
- Created `docs/QUICK_START_v4_1_0.md` - User-friendly quick start guide
- Created `docs/TESTING_GUIDE_v4_1_0.md` - Comprehensive testing procedures
- Created `RELEASE_NOTES_v4.1.0.md` - Detailed release notes

### Fixed
- Docker module now properly uses centralized logging library
- Dry-run mode consistently suppresses sudo prompts across all new modules
- All new modules follow project coding standards and conventions

## [4.0.7] - 2026-01-13

### Added
- GitHub Actions workflow for full test suite and smoke tests (.github/workflows/test.yml)
- Dependabot config for GitHub Actions updates (.github/dependabot.yml)
- SECURITY.md with vulnerability reporting policy
- CONTRIBUTING.md with development workflow guidelines

### Fixed
- Removed stray 'done' in Makefile test-quick target causing syntax error

## [4.0.6] - 2026-01-13

### Added
- Root/sudo access check in post_install scripts (prevents accidental non-sudo execution)
- Enhanced error logging with timestamp, PWD, and filtered environment variables
- Selective retry mechanism for transient network failures (apt-get update)
- Comprehensive pre-push audit validation

### Fixed
- Consolidated duplicate `test-quick` target definitions in Makefile
- Removed eval-based execution vulnerabilities in post_install scripts
- Fixed rc capture bug in run_must function (proper if/else pattern)
- Eliminated IFS+array+eval multiline command splitting issue

### Changed
- Migrated from eval-based to argv-based execution model for security
- Enhanced log_error() to capture filtered environment context
- Applied retry mechanism to all 3 apt-get update call sites

### Security
- Removed all eval usage from privileged command execution
- Environment variable logging now filters to safe vars only (DEBIAN|APT|HOME|USER|PATH)

## [4.0.5] - Earlier

### Fixed
- Self-test suite no longer hangs
- Bootstrap_check.sh syntax errors resolved

## Earlier Versions

See git history for detailed changes in versions prior to 4.0.5.

---

[Unreleased]: https://github.com/T-Green-hub/ubuntu-bootstrap/compare/v4.0.7...HEAD
[4.0.7]: https://github.com/T-Green-hub/ubuntu-bootstrap/compare/v4.0.6...v4.0.7
[4.0.6]: https://github.com/T-Green-hub/ubuntu-bootstrap/releases/tag/v4.0.6
[4.0.5]: https://github.com/T-Green-hub/ubuntu-bootstrap/releases/tag/v4.0.5
