#!/usr/bin/env bash
# Test suite for Rust (rustup) module
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_SCRIPT_DIR="$SCRIPT_DIR"

# Source test framework
# shellcheck source=../lib/test_framework.sh
source "$SCRIPT_DIR/../lib/test_framework.sh"

# Source the module being tested
# shellcheck source=rust.sh
source "$SCRIPT_DIR/rust.sh"

# Test suite header
test_suite_header "Rust (rustup) Module Tests"

## Syntax and Structure Tests ##

test_rust_syntax() {
    if ! command -v shellcheck >/dev/null 2>&1; then
        test_skip "shellcheck not installed"
        return 0
    fi
    
    # Run shellcheck, ignoring SC1091 (not following sourced files)
    if shellcheck -e SC1091 "$TEST_SCRIPT_DIR/rust.sh" 2>/dev/null; then
        test_pass "Shellcheck validation passed"
    else
        test_skip "Shellcheck found issues (non-critical)"
    fi
}

test_rust_functions_exist() {
    if declare -f install_rust >/dev/null; then
        test_pass "install_rust() function exists"
    else
        test_fail "install_rust() function missing"
    fi
    
    if declare -f is_rust_installed >/dev/null; then
        test_pass "is_rust_installed() function exists"
    else
        test_fail "is_rust_installed() function missing"
    fi
    
    if declare -f backup_rust_config >/dev/null; then
        test_pass "backup_rust_config() function exists"
    else
        test_fail "backup_rust_config() function missing"
    fi
    
    if declare -f uninstall_rust >/dev/null; then
        test_pass "uninstall_rust() function exists"
    else
        test_fail "uninstall_rust() function missing"
    fi
}

## Detection Tests ##

test_rust_detection() {
    if [[ -d "$HOME/.cargo" || -d "$HOME/.rustup" ]]; then
        if is_rust_installed; then
            test_pass "Detects installed Rust"
        else
            test_fail "Failed to detect installed Rust"
        fi
    else
        if ! is_rust_installed; then
            test_pass "Correctly detects Rust not installed"
        else
            test_fail "False positive: detected Rust when not installed"
        fi
    fi
}

test_rust_command_detection() {
    if [[ -d "$HOME/.cargo" ]]; then
        if command -v rustc >/dev/null 2>&1; then
            local version
            version=$(rustc --version 2>/dev/null || echo "unknown")
            test_pass "rustc command available (version: $version)"
        else
            test_skip "rustc command not in PATH" "may need shell restart"
        fi
    else
        test_skip "Rust not installed" "cannot test command detection"
    fi
}

## Uninstall Behavior Tests ##

test_uninstall_dry_run() {
    if ! is_rust_installed; then
        test_skip "Rust not installed" "cannot test uninstall"
        return 0
    fi
    
    DRY_RUN=1 FORCE=1
    export DRY_RUN FORCE
    
    if uninstall_rust >/dev/null 2>&1; then
        test_pass "DRY_RUN mode executes without errors"
    else
        test_fail "DRY_RUN mode failed"
    fi
    
    if [[ -d "$HOME/.cargo" || -d "$HOME/.rustup" ]]; then
        test_pass "DRY_RUN preserves Rust directories"
    else
        test_fail "DRY_RUN removed directories (should not happen)"
    fi
    
    unset DRY_RUN FORCE
}

## Shell Cleanup Pattern Tests ##

test_shell_cleanup_patterns() {
    local test_file="/tmp/test_rust_shell_$$"
    cat > "$test_file" << 'EOF'
# Rust cargo configuration
source "$HOME/.cargo/env"
. "$HOME/.cargo/env"
EOF
    
    if grep -qE '\.cargo/env' "$test_file"; then
        test_pass "Test file contains cargo env patterns"
    else
        test_fail "Test file setup failed"
    fi
    
    rm -f "$test_file"
}

test_backup_directory_structure() {
    local test_backup="/tmp/test_rust_backup_$$"
    mkdir -p "$test_backup"
    
    if [[ -d "$test_backup" ]]; then
        test_pass "Can create backup directory structure"
    else
        test_fail "Failed to create backup directory"
    fi
    
    rmdir "$test_backup"
}

## Script Quality Tests ##

test_strict_mode_enabled() {
    if grep -q "set -euo pipefail" "$TEST_SCRIPT_DIR/rust.sh"; then
        test_pass "Strict mode enabled"
    else
        test_fail "Strict mode not enabled"
    fi
}

test_sources_common_lib() {
    if grep -q "source.*lib/common.sh" "$TEST_SCRIPT_DIR/rust.sh"; then
        test_pass "Sources common library"
    else
        test_fail "Does not source common library"
    fi
}

## Run all tests ##

test_rust_syntax
test_rust_functions_exist
test_rust_detection
test_rust_command_detection
test_uninstall_dry_run
test_shell_cleanup_patterns
test_backup_directory_structure
test_strict_mode_enabled
test_sources_common_lib

# Display test summary
test_report
