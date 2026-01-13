# Changelog

All notable changes to the Ubuntu Bootstrap project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
