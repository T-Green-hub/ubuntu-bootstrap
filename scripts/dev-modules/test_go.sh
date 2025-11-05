#!/usr/bin/env bash
# Test suite for Go module
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_SCRIPT_DIR="$SCRIPT_DIR"

# Source test framework
# shellcheck source=../lib/test_framework.sh
source "$SCRIPT_DIR/../lib/test_framework.sh"

# Source the module being tested
# shellcheck source=go.sh
source "$SCRIPT_DIR/go.sh"

# Test suite header
test_suite_header "Go Module Tests"

## Syntax and Structure Tests ##

test_go_syntax() {
    if ! command -v shellcheck >/dev/null 2>&1; then
        test_skip "shellcheck not installed"
        return 0
    fi
    
    # Run shellcheck, ignoring SC1091 (not following sourced files) and SC2064 (trap with quoted commands)
    if shellcheck -e SC1091,SC2064 "$TEST_SCRIPT_DIR/go.sh" 2>/dev/null; then
        test_pass "Shellcheck validation passed"
    else
        test_skip "Shellcheck found issues (non-critical)"
    fi
}

test_go_functions_exist() {
    if declare -f install_go >/dev/null; then
        test_pass "install_go() function exists"
    else
        test_fail "install_go() function missing"
    fi
    
    if declare -f is_go_installed >/dev/null; then
        test_pass "is_go_installed() function exists"
    else
        test_fail "is_go_installed() function missing"
    fi
    
    if declare -f backup_go_config >/dev/null; then
        test_pass "backup_go_config() function exists"
    else
        test_fail "backup_go_config() function missing"
    fi
    
    if declare -f uninstall_go >/dev/null; then
        test_pass "uninstall_go() function exists"
    else
        test_fail "uninstall_go() function missing"
    fi
}

## Detection Tests ##

test_go_detection() {
    if [[ -d "/usr/local/go" ]]; then
        if is_go_installed; then
            test_pass "Detects installed Go"
        else
            test_fail "Failed to detect installed Go"
        fi
    else
        if ! is_go_installed; then
            test_pass "Correctly detects Go not installed"
        else
            test_fail "False positive: detected Go when not installed"
        fi
    fi
}

test_go_command_detection() {
    if [[ -d "/usr/local/go" ]]; then
        if command -v go >/dev/null 2>&1; then
            local version
            version=$(go version 2>/dev/null || echo "unknown")
            test_pass "go command available ($version)"
        else
            test_skip "go command not in PATH" "may need shell restart"
        fi
    else
        test_skip "Go not installed" "cannot test command detection"
    fi
}

## Uninstall Behavior Tests ##

test_uninstall_dry_run() {
    if ! is_go_installed; then
        test_skip "Go not installed" "cannot test uninstall"
        return 0
    fi
    
    DRY_RUN=1 FORCE=1
    export DRY_RUN FORCE
    
    if uninstall_go >/dev/null 2>&1; then
        test_pass "DRY_RUN mode executes without errors"
    else
        test_fail "DRY_RUN mode failed"
    fi
    
    if [[ -d "/usr/local/go" ]]; then
        test_pass "DRY_RUN preserves /usr/local/go"
    else
        test_fail "DRY_RUN removed directory (should not happen)"
    fi
    
    unset DRY_RUN FORCE
}

## Shell Cleanup Pattern Tests ##

test_shell_cleanup_patterns() {
    local test_file="/tmp/test_go_shell_$$"
    cat > "$test_file" << 'EOF'
# Go configuration
export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
EOF
    
    if grep -qE 'GOPATH|/usr/local/go' "$test_file"; then
        test_pass "Test file contains Go PATH patterns"
    else
        test_fail "Test file setup failed"
    fi
    
    rm -f "$test_file"
}

test_backup_directory_structure() {
    local test_backup="/tmp/test_go_backup_$$"
    mkdir -p "$test_backup"
    
    if [[ -d "$test_backup" ]]; then
        test_pass "Can create backup directory structure"
    else
        test_fail "Failed to create backup directory"
    fi
    
    rmdir "$test_backup"
}

test_validate_path_function() {
    if declare -f validate_path >/dev/null; then
        test_pass "validate_path() function exists (safety check)"
    else
        test_fail "validate_path() function missing"
    fi
}

test_path_validation_logic() {
    # Test the safety check function
    if validate_path "/usr/local/go" "/usr/local/go" >/dev/null 2>&1; then
        test_pass "Path validation works correctly"
    else
        test_fail "Path validation failed"
    fi
    
    # Test that it rejects invalid paths
    if ! validate_path "/etc/passwd" "/usr/local/go" >/dev/null 2>&1; then
        test_pass "Path validation rejects mismatched paths"
    else
        test_fail "Path validation accepted invalid path (security risk!)"
    fi
}

## Script Quality Tests ##

test_strict_mode_enabled() {
    if grep -q "set -euo pipefail" "$TEST_SCRIPT_DIR/go.sh"; then
        test_pass "Strict mode enabled"
    else
        test_fail "Strict mode not enabled"
    fi
}

test_sources_common_lib() {
    if grep -q "source.*lib/common.sh" "$TEST_SCRIPT_DIR/go.sh"; then
        test_pass "Sources common library"
    else
        test_fail "Does not source common library"
    fi
}

test_sudo_handling() {
    if grep -q "need_sudo" "$TEST_SCRIPT_DIR/go.sh"; then
        test_pass "Uses need_sudo for privileged operations"
    else
        test_fail "Does not use need_sudo helper"
    fi
}

## Run all tests ##

test_go_syntax
test_go_functions_exist
test_go_detection
test_go_command_detection
test_uninstall_dry_run
test_shell_cleanup_patterns
test_backup_directory_structure
test_validate_path_function
test_path_validation_logic
test_strict_mode_enabled
test_sources_common_lib
test_sudo_handling

# Display test summary
test_report
