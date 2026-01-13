#!/usr/bin/env bash
# Logging utilities for ubuntu-bootstrap
# Provides consistent timestamped logging with severity levels

# Colors for output
readonly LOG_RED='\033[0;31m'
readonly LOG_GREEN='\033[0;32m'
readonly LOG_YELLOW='\033[1;33m'
readonly LOG_BLUE='\033[0;34m'
readonly LOG_CYAN='\033[0;36m'
readonly LOG_NC='\033[0m'

# Global log file path (set by caller)
LOG_FILE="${LOG_FILE:-}"

# Base log function with timestamp
log_msg() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp
    timestamp="$(date -Iseconds)"
    
    # To stdout/stderr
    printf '[%s] [%s] %s\n' "$timestamp" "$level" "$msg"
    
    # To file if configured
    if [[ -n "${LOG_FILE:-}" ]]; then
        printf '[%s] [%s] %s\n' "$timestamp" "$level" "$msg" >> "$LOG_FILE"
    fi
}

log_info() {
    echo -e "${LOG_BLUE}ℹ${LOG_NC} $*"
    log_msg "INFO" "$*"
}

log_success() {
    echo -e "${LOG_GREEN}✓${LOG_NC} $*"
    log_msg "SUCCESS" "$*"
}

log_warning() {
    echo -e "${LOG_YELLOW}⚠${LOG_NC} $*"
    log_msg "WARNING" "$*"
}

log_error() {
    echo -e "${LOG_RED}✗${LOG_NC} $*" >&2
    log_msg "ERROR" "$*"
}

log_step() {
    echo ""
    echo -e "${LOG_CYAN}▶${LOG_NC} ${LOG_CYAN}$*${LOG_NC}"
    log_msg "STEP" "$*"
}

# Simple log without decoration
log() {
    printf '[%s] %s\n' "$(date -Iseconds)" "$*"
    if [[ -n "${LOG_FILE:-}" ]]; then
        printf '[%s] %s\n' "$(date -Iseconds)" "$*" >> "$LOG_FILE"
    fi
}
