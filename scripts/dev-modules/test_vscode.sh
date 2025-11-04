#!/usr/bin/env bash
# Test suite for VS Code module

set -euo pipefail

TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$TEST_SCRIPT_DIR/../.." && pwd)"

# Source test framework
source "${REPO_DIR}/scripts/lib/test_framework.sh"

# Source common utilities
source "${REPO_DIR}/scripts/lib/common.sh"

# Source VS Code module
source "${TEST_SCRIPT_DIR}/vscode.sh"

###############################################################################
# Test Cases
###############################################################################

test_vscode_syntax() {
    local syntax_check
    syntax_check=$(bash -n "${TEST_SCRIPT_DIR}/vscode.sh" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        test_pass "vscode.sh has valid syntax"
        return 0
    else
        test_fail "vscode.sh has syntax errors: $syntax_check"
        return 1
    fi
}

test_vscode_functions_exist() {
    if declare -f install_vscode >/dev/null 2>&1; then
        test_pass "install_vscode function exists"
    else
        test_fail "install_vscode function NOT defined"
    fi
    
    if declare -f uninstall_vscode >/dev/null 2>&1; then
        test_pass "uninstall_vscode function exists"
    else
        test_fail "uninstall_vscode function NOT defined"
    fi
    
    if declare -f is_vscode_installed >/dev/null 2>&1; then
        test_pass "is_vscode_installed function exists"
    else
        test_fail "is_vscode_installed function NOT defined"
    fi
    
    if declare -f backup_vscode_config >/dev/null 2>&1; then
        test_pass "backup_vscode_config function exists"
    else
        test_fail "backup_vscode_config function NOT defined"
    fi
}

test_vscode_detection() {
    if is_vscode_installed; then
        test_pass "VS Code detection works (installed)"
    else
        test_skip "VS Code not installed" "install it to test detection"
    fi
}

test_vscode_command_availability() {
    if command -v code >/dev/null 2>&1; then
        test_pass "VS Code command 'code' is available"
        
        # Test version
        local version
        version=$(code --version 2>/dev/null | head -1 || echo "")
        if [[ -n "$version" ]]; then
            test_pass "VS Code version: $version"
        fi
    else
        test_skip "VS Code command not available" "not installed"
    fi
}

test_vscode_package_status() {
    if dpkg -s code >/dev/null 2>&1; then
        test_pass "VS Code package is installed"
    else
        test_skip "VS Code package not installed"
    fi
}

test_vscode_repository_files() {
    if [[ -f /etc/apt/sources.list.d/vscode.list ]]; then
        test_pass "VS Code repository file exists"
    else
        test_skip "VS Code repository file not found" "not installed or removed"
    fi
    
    if [[ -f /usr/share/keyrings/packages.microsoft.gpg ]]; then
        test_pass "Microsoft GPG key exists"
    else
        test_skip "Microsoft GPG key not found" "not installed or removed"
    fi
}

test_vscode_dry_run_uninstall() {
    local before_installed
    before_installed=$(is_vscode_installed && echo "yes" || echo "no")
    
    # Run uninstall in dry-run mode
    DRY_RUN=1 FORCE=1 uninstall_vscode >/dev/null 2>&1 || true
    
    local after_installed
    after_installed=$(is_vscode_installed && echo "yes" || echo "no")
    
    if [[ "$after_installed" == "$before_installed" ]]; then
        test_pass "DRY_RUN mode did not change installation state"
    else
        test_fail "DRY_RUN mode changed installation state (before: $before_installed, after: $after_installed)"
    fi
}

test_vscode_backup_function() {
    local temp_backup
    temp_backup=$(mktemp -d)
    
    if backup_vscode_config "$temp_backup/test-backup" >/dev/null 2>&1; then
        if [[ -d "$temp_backup/test-backup" ]]; then
            test_pass "Backup function creates directory"
            rm -rf "$temp_backup"
        else
            test_fail "Backup function did not create directory"
            rm -rf "$temp_backup"
        fi
    else
        test_fail "Backup function failed"
        rm -rf "$temp_backup"
    fi
}

test_vscode_uninstall_with_force() {
    if ! is_vscode_installed; then
        test_skip "Cannot test uninstall" "VS Code not installed"
        return 0
    fi
    
    # Test with dry-run + force (safe to test)
    if DRY_RUN=1 FORCE=1 uninstall_vscode >/dev/null 2>&1; then
        test_pass "Uninstall accepts FORCE=1 flag"
    else
        test_fail "Uninstall failed with FORCE=1 flag"
    fi
}

test_vscode_not_installed_handling() {
    # Test behavior when VS Code is not installed
    DRY_RUN=1 FORCE=1 uninstall_vscode >/dev/null 2>&1
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        test_pass "Uninstall handles 'not installed' state gracefully (exit 0)"
    else
        test_fail "Uninstall failed when handling uninstalled state (exit $exit_code)"
    fi
}

###############################################################################
# Main Test Runner
###############################################################################

main() {
    test_suite_header "VS Code Module Test Suite"
    
    run_test test_vscode_syntax
    run_test test_vscode_functions_exist
    run_test test_vscode_detection
    run_test test_vscode_command_availability
    run_test test_vscode_package_status
    run_test test_vscode_repository_files
    run_test test_vscode_dry_run_uninstall
    run_test test_vscode_backup_function
    run_test test_vscode_uninstall_with_force
    run_test test_vscode_not_installed_handling
    
    test_report
}

main "$@"
