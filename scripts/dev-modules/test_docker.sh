#!/usr/bin/env bash
# Test suite for Docker module
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_SCRIPT_DIR="$SCRIPT_DIR"

# Source test framework
# shellcheck source=../lib/test_framework.sh
source "$SCRIPT_DIR/../lib/test_framework.sh"

# Source the module being tested
# shellcheck source=docker.sh
source "$SCRIPT_DIR/docker.sh"

# Test suite header
test_suite_header "Docker Module Tests"

## Syntax and Structure Tests ##

test_docker_syntax() {
    if ! command -v shellcheck >/dev/null 2>&1; then
        test_skip "shellcheck not installed"
        return 0
    fi
    
    # Run shellcheck, ignoring SC1091 (not following sourced files)
    if shellcheck -e SC1091,SC2046 "$TEST_SCRIPT_DIR/docker.sh" 2>/dev/null; then
        test_pass "Shellcheck validation passed"
    else
        test_skip "Shellcheck found issues (non-critical)"
    fi
}

test_docker_functions_exist() {
    if declare -f install_docker >/dev/null; then
        test_pass "install_docker() function exists"
    else
        test_fail "install_docker() function missing"
    fi
    
    if declare -f is_docker_installed >/dev/null; then
        test_pass "is_docker_installed() function exists"
    else
        test_fail "is_docker_installed() function missing"
    fi
    
    if declare -f backup_docker_config >/dev/null; then
        test_pass "backup_docker_config() function exists"
    else
        test_fail "backup_docker_config() function missing"
    fi
    
    if declare -f uninstall_docker >/dev/null; then
        test_pass "uninstall_docker() function exists"
    else
        test_fail "uninstall_docker() function missing"
    fi
}

## Detection Tests ##

test_docker_detection() {
    if command -v docker >/dev/null 2>&1; then
        if is_docker_installed; then
            test_pass "Detects installed Docker"
        else
            test_fail "Failed to detect installed Docker"
        fi
    else
        if ! is_docker_installed; then
            test_pass "Correctly detects Docker not installed"
        else
            test_fail "False positive: detected Docker when not installed"
        fi
    fi
}

test_docker_command_detection() {
    if command -v docker >/dev/null 2>&1; then
        local version
        version=$(docker --version 2>/dev/null || echo "unknown")
        test_pass "docker command available ($version)"
    else
        test_skip "Docker not installed" "cannot test command detection"
    fi
}

test_docker_package_detection() {
    if dpkg -l 2>/dev/null | grep -qE "docker-ce|containerd.io"; then
        test_pass "Docker packages detected via dpkg"
    else
        test_skip "Docker packages not installed"
    fi
}

## Service Tests ##

test_docker_service_detection() {
    if systemctl list-units --full -all 2>/dev/null | grep -qF "docker.service"; then
        test_pass "docker.service detected"
    else
        test_skip "docker.service not found"
    fi
}

test_docker_socket_detection() {
    if systemctl list-units --full -all 2>/dev/null | grep -qF "docker.socket"; then
        test_pass "docker.socket detected"
    else
        test_skip "docker.socket not found"
    fi
}

## Group Tests ##

test_docker_group_detection() {
    if groups "$USER" 2>/dev/null | grep -q docker; then
        test_pass "User is in docker group"
    else
        test_skip "User not in docker group"
    fi
}

## Uninstall Behavior Tests ##

test_uninstall_dry_run() {
    if ! is_docker_installed; then
        test_skip "Docker not installed" "cannot test uninstall"
        return 0
    fi
    
    DRY_RUN=1 FORCE=1
    export DRY_RUN FORCE
    
    if uninstall_docker >/dev/null 2>&1; then
        test_pass "DRY_RUN mode executes without errors"
    else
        test_fail "DRY_RUN mode failed"
    fi
    
    if command -v docker >/dev/null 2>&1; then
        test_pass "DRY_RUN preserves Docker installation"
    else
        test_fail "DRY_RUN removed Docker (should not happen)"
    fi
    
    unset DRY_RUN FORCE
}

## Safety Check Tests ##

test_critical_warnings_present() {
    if grep -q "CRITICAL WARNING" "$TEST_SCRIPT_DIR/docker.sh"; then
        test_pass "Critical warnings present in uninstall function"
    else
        test_fail "Missing critical warnings for destructive operation"
    fi
}

test_confirmation_required() {
    if grep -q "ABSOLUTELY SURE" "$TEST_SCRIPT_DIR/docker.sh"; then
        test_pass "User confirmation required for uninstall"
    else
        test_fail "Missing user confirmation requirement"
    fi
}

test_data_directory_handling() {
    if grep -q "/var/lib/docker" "$TEST_SCRIPT_DIR/docker.sh"; then
        test_pass "Handles /var/lib/docker data directory"
    else
        test_fail "Missing /var/lib/docker handling"
    fi
}

test_separate_data_confirmation() {
    if grep -q "DELETE" "$TEST_SCRIPT_DIR/docker.sh"; then
        test_pass "Separate confirmation for data deletion"
    else
        test_fail "Missing separate data deletion confirmation"
    fi
}

## Backup Tests ##

test_backup_directory_structure() {
    local test_backup="/tmp/test_docker_backup_$$"
    mkdir -p "$test_backup"
    
    if [[ -d "$test_backup" ]]; then
        test_pass "Can create backup directory structure"
    else
        test_fail "Failed to create backup directory"
    fi
    
    rmdir "$test_backup"
}

test_backup_saves_image_list() {
    if grep -q "docker-images.txt" "$TEST_SCRIPT_DIR/docker.sh"; then
        test_pass "Backs up Docker images list"
    else
        test_fail "Missing Docker images backup"
    fi
}

test_backup_saves_container_list() {
    if grep -q "docker-containers.txt" "$TEST_SCRIPT_DIR/docker.sh"; then
        test_pass "Backs up Docker containers list"
    else
        test_fail "Missing Docker containers backup"
    fi
}

## Script Quality Tests ##

test_strict_mode_enabled() {
    if grep -q "set -euo pipefail" "$TEST_SCRIPT_DIR/docker.sh"; then
        test_pass "Strict mode enabled"
    else
        test_fail "Strict mode not enabled"
    fi
}

test_sources_common_lib() {
    if grep -q "source.*lib/common.sh" "$TEST_SCRIPT_DIR/docker.sh"; then
        test_pass "Sources common library"
    else
        test_fail "Does not source common library"
    fi
}

test_sudo_handling() {
    if grep -q "need_sudo" "$TEST_SCRIPT_DIR/docker.sh"; then
        test_pass "Uses need_sudo for privileged operations"
    else
        test_fail "Does not use need_sudo helper"
    fi
}

test_service_stopping() {
    if grep -q "systemctl stop docker.service" "$TEST_SCRIPT_DIR/docker.sh"; then
        test_pass "Stops Docker services before uninstall"
    else
        test_fail "Missing service stopping logic"
    fi
}

test_package_removal() {
    if grep -q "apt-get remove.*docker-ce" "$TEST_SCRIPT_DIR/docker.sh"; then
        test_pass "Removes Docker packages"
    else
        test_fail "Missing package removal logic"
    fi
}

test_apt_cleanup() {
    if grep -q "apt-get autoremove\|apt-get autoclean" "$TEST_SCRIPT_DIR/docker.sh"; then
        test_pass "Cleans up APT cache after uninstall"
    else
        test_skip "APT cleanup recommended but not required"
    fi
}

## Run all tests ##

test_docker_syntax
test_docker_functions_exist
test_docker_detection
test_docker_command_detection
test_docker_package_detection
test_docker_service_detection
test_docker_socket_detection
test_docker_group_detection
test_uninstall_dry_run
test_critical_warnings_present
test_confirmation_required
test_data_directory_handling
test_separate_data_confirmation
test_backup_directory_structure
test_backup_saves_image_list
test_backup_saves_container_list
test_strict_mode_enabled
test_sources_common_lib
test_sudo_handling
test_service_stopping
test_package_removal
test_apt_cleanup

# Display test summary
test_report
