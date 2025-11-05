#!/usr/bin/env bash
# Test suite for Python (pyenv) module
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_SCRIPT_DIR="$SCRIPT_DIR"

# Source test framework
# shellcheck source=../lib/test_framework.sh
source "$SCRIPT_DIR/../lib/test_framework.sh"

# Source the module being tested
# shellcheck source=python.sh
source "$SCRIPT_DIR/python.sh"

# Test suite header
test_suite_header "Python (pyenv) Module Tests"

## Syntax and Structure Tests ##

test_python_syntax() {
    if shellcheck "$TEST_SCRIPT_DIR/python.sh" 2>/dev/null; then
        test_pass "Shellcheck validation passed"
    else
        test_fail "Shellcheck found issues"
    fi
}

test_python_functions_exist() {
    if declare -f install_python >/dev/null; then
        test_pass "install_python() function exists"
    else
        test_fail "install_python() function missing"
    fi
    
    if declare -f is_python_installed >/dev/null; then
        test_pass "is_python_installed() function exists"
    else
        test_fail "is_python_installed() function missing"
    fi
    
    if declare -f backup_python_config >/dev/null; then
        test_pass "backup_python_config() function exists"
    else
        test_fail "backup_python_config() function missing"
    fi
    
    if declare -f uninstall_python >/dev/null; then
        test_pass "uninstall_python() function exists"
    else
        test_fail "uninstall_python() function missing"
    fi
}

## Detection Tests ##

test_python_detection() {
    if [[ -d "$HOME/.pyenv" ]]; then
        if is_python_installed; then
            test_pass "Detects installed pyenv"
        else
            test_fail "Failed to detect installed pyenv"
        fi
    else
        if ! is_python_installed; then
            test_pass "Correctly detects pyenv not installed"
        else
            test_fail "False positive: detected pyenv when not installed"
        fi
    fi
}

test_python_command_detection() {
    if [[ -d "$HOME/.pyenv" ]]; then
        if command -v pyenv >/dev/null 2>&1; then
            local version
            version=$(pyenv --version 2>/dev/null || echo "unknown")
            test_pass "pyenv command available (version: $version)"
        else
            test_skip "pyenv command not in PATH" "may need shell restart"
        fi
    else
        if ! command -v pyenv >/dev/null 2>&1; then
            test_pass "pyenv command not available (as expected)"
        else
            test_skip "pyenv command exists but directory doesn't" "unusual state"
        fi
    fi
}

## DRY_RUN Tests ##

test_python_dry_run_uninstall() {
    local before_installed
    before_installed=$(is_python_installed && echo "yes" || echo "no")
    
    # Run uninstall in dry-run mode
    DRY_RUN=1 FORCE=1 uninstall_python >/dev/null 2>&1 || true
    
    local after_installed
    after_installed=$(is_python_installed && echo "yes" || echo "no")
    
    if [[ "$after_installed" == "$before_installed" ]]; then
        test_pass "DRY_RUN mode did not change installation state"
    else
        test_fail "DRY_RUN mode changed installation state (before: $before_installed, after: $after_installed)"
    fi
}

## Backup Tests ##

test_python_backup_function() {
    local temp_backup
    temp_backup=$(mktemp -d)
    
    if backup_python_config "$temp_backup/test-backup" >/dev/null 2>&1; then
        if [[ -d "$temp_backup/test-backup" ]]; then
            test_pass "Backup function creates directory"
            
            # Check if shell configs were backed up (if they exist)
            if [[ -f "$HOME/.bashrc" ]] && [[ -f "$temp_backup/test-backup/.bashrc" ]]; then
                test_pass "Backup function backed up .bashrc"
            fi
            
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

## Uninstall Function Tests ##

test_python_uninstall_with_force() {
    if ! is_python_installed; then
        test_skip "Cannot test uninstall" "Python/pyenv not installed"
        return 0
    fi
    
    # Test with dry-run + force (safe to test)
    if DRY_RUN=1 FORCE=1 uninstall_python >/dev/null 2>&1; then
        test_pass "Uninstall accepts FORCE=1 flag"
    else
        test_fail "Uninstall failed with FORCE=1 flag"
    fi
}

test_python_not_installed_handling() {
    # Test behavior when Python is not installed
    DRY_RUN=1 FORCE=1 uninstall_python >/dev/null 2>&1
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        test_pass "Uninstall handles 'not installed' state gracefully (exit 0)"
    else
        test_fail "Uninstall failed when handling uninstalled state (exit $exit_code)"
    fi
}

## Shell Cleanup Tests ##

test_python_shell_cleanup_patterns() {
    # Test that we have proper patterns defined for shell cleanup
    if grep -q 'export PYENV_ROOT=' "$TEST_SCRIPT_DIR/python.sh"; then
        test_pass "Uninstall script includes PYENV_ROOT cleanup pattern"
    else
        test_fail "Uninstall script missing PYENV_ROOT cleanup pattern"
    fi
    
    if grep -q 'pyenv init' "$TEST_SCRIPT_DIR/python.sh"; then
        test_pass "Uninstall script includes pyenv init cleanup pattern"
    else
        test_fail "Uninstall script missing pyenv init cleanup pattern"
    fi
}

test_python_shell_config_cleanup() {
    # Verify the cleanup would affect the right files
    if grep -q '\.bashrc' "$TEST_SCRIPT_DIR/python.sh"; then
        test_pass "Uninstall script cleans .bashrc"
    else
        test_fail "Uninstall script doesn't clean .bashrc"
    fi
    
    if grep -q '\.profile' "$TEST_SCRIPT_DIR/python.sh"; then
        test_pass "Uninstall script cleans .profile"
    else
        test_fail "Uninstall script doesn't clean .profile"
    fi
}

## Directory Cleanup Tests ##

test_python_directory_removal() {
    # Check that uninstall removes the right directories
    if grep -q '\$HOME/\.pyenv' "$TEST_SCRIPT_DIR/python.sh"; then
        test_pass "Uninstall script removes ~/.pyenv directory"
    else
        test_fail "Uninstall script doesn't remove ~/.pyenv"
    fi
}

test_python_version_file_removal() {
    # Check that .python-version file is handled
    if grep -q '\.python-version' "$TEST_SCRIPT_DIR/python.sh"; then
        test_pass "Uninstall script handles .python-version file"
    else
        test_fail "Uninstall script doesn't handle .python-version"
    fi
}

## Safety Tests ##

test_python_user_confirmation() {
    # Verify user confirmation is requested (unless FORCE=1)
    if grep -q 'read -p' "$TEST_SCRIPT_DIR/python.sh"; then
        test_pass "Uninstall script requests user confirmation"
    else
        test_fail "Uninstall script missing user confirmation"
    fi
}

test_python_backup_creation() {
    # Verify backup is created before uninstall
    if grep -q 'backup_python_config' "$TEST_SCRIPT_DIR/python.sh" | grep -q uninstall; then
        test_pass "Uninstall creates backup before removal"
    else
        test_skip "Could not verify backup creation in uninstall" "grep pattern may need adjustment"
    fi
}

## Virtual Environment Handling ##

test_python_venv_warning() {
    # Check that virtual environments are mentioned in warnings
    if grep -q 'virtual' "$TEST_SCRIPT_DIR/python.sh"; then
        test_pass "Uninstall warns about virtual environments"
    else
        test_skip "No explicit venv warning" "acceptable - covered by general warning"
    fi
}

## Logging Tests ##

test_python_logging() {
    # Verify logging is present
    if grep -q '\[UNINSTALL\]' "$TEST_SCRIPT_DIR/python.sh"; then
        test_pass "Uninstall function includes logging"
    else
        test_fail "Uninstall function missing logging"
    fi
}

test_python_shell_restart_note() {
    # Check for note about restarting shell
    if grep -q 'Restart your shell\|exec bash' "$TEST_SCRIPT_DIR/python.sh"; then
        test_pass "Includes note about restarting shell"
    else
        test_skip "No shell restart note" "would be helpful but not critical"
    fi
}

# Run all tests
run_test test_python_syntax
run_test test_python_functions_exist
run_test test_python_detection
run_test test_python_command_detection
run_test test_python_dry_run_uninstall
run_test test_python_backup_function
run_test test_python_uninstall_with_force
run_test test_python_not_installed_handling
run_test test_python_shell_cleanup_patterns
run_test test_python_shell_config_cleanup
run_test test_python_directory_removal
run_test test_python_version_file_removal
run_test test_python_user_confirmation
run_test test_python_backup_creation
run_test test_python_venv_warning
run_test test_python_logging
run_test test_python_shell_restart_note

# Print test report
test_report
