#!/usr/bin/env bash
# Package management utilities for ubuntu-bootstrap
# Safe, idempotent apt operations with lock handling

# Source logging if not already loaded
if ! declare -F log_info >/dev/null 2>&1; then
    SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_LIB_DIR/logging.sh"
fi

# Returns "sudo" if not running as root, empty string otherwise
need_sudo() {
    if [[ $EUID -ne 0 ]]; then
        echo "sudo"
    fi
}

# Check if package is installed
is_package_installed() {
    local pkg="$1"
    dpkg -s "$pkg" >/dev/null 2>&1
}

# Wait for dpkg/apt locks with timeout
wait_for_apt_lock() {
    local timeout="${1:-180}"
    local waited=0
    local lock_files=(
        "/var/lib/dpkg/lock-frontend"
        "/var/lib/dpkg/lock"
        "/var/lib/apt/lists/lock"
    )
    
    while true; do
        local busy=0
        
        # Check if any lock file is in use
        for lock_file in "${lock_files[@]}"; do
            if [[ -f "$lock_file" ]]; then
                if command -v fuser >/dev/null 2>&1; then
                    if $(need_sudo) fuser "$lock_file" >/dev/null 2>&1; then
                        busy=1
                        break
                    fi
                fi
            fi
        done
        
        # Check for running package managers
        if pgrep -x "apt-get|apt|dpkg|unattended-upgr" >/dev/null 2>&1; then
            busy=1
        fi
        
        if (( busy == 0 )); then
            break
        fi
        
        if (( waited == 0 )); then
            log_info "Waiting for apt/dpkg locks to be released..."
        fi
        
        sleep 2
        waited=$((waited + 2))
        
        if (( waited >= timeout )); then
            log_warning "Timeout waiting for apt locks after ${timeout}s"
            return 1
        fi
    done
    
    return 0
}

# Safe apt-get wrapper with retries
apt_safe() {
    local max_attempts=3
    local attempt=0
    local wait_time=5
    
    while ((attempt < max_attempts)); do
        ((attempt++))
        
        # Wait for locks
        if ! wait_for_apt_lock 60; then
            if ((attempt < max_attempts)); then
                log_warning "Retrying apt operation (attempt $attempt/$max_attempts)..."
                sleep "$wait_time"
                continue
            else
                log_error "Failed to acquire apt lock after $max_attempts attempts"
                return 1
            fi
        fi
        
        # Execute apt command
        if $(need_sudo) apt-get "$@"; then
            return 0
        else
            local exit_code=$?
            if ((attempt < max_attempts)); then
                log_warning "apt-get failed (exit $exit_code), retrying (attempt $attempt/$max_attempts)..."
                sleep "$wait_time"
            else
                log_error "apt-get failed after $max_attempts attempts"
                return $exit_code
            fi
        fi
    done
    
    return 1
}

# Update apt cache
apt_update() {
    log_step "Updating package cache..."
    apt_safe update -qq
}

# Upgrade packages
apt_upgrade() {
    log_step "Upgrading packages..."
    apt_safe upgrade -y
}

# Install packages (idempotent, only installs if not present)
apt_install() {
    local packages=("$@")
    local to_install=()
    
    # Filter packages that aren't already installed
    for pkg in "${packages[@]}"; do
        if ! is_package_installed "$pkg"; then
            to_install+=("$pkg")
        fi
    done
    
    if (( ${#to_install[@]} == 0 )); then
        log_info "All packages already installed: ${packages[*]}"
        return 0
    fi
    
    log_info "Installing packages: ${to_install[*]}"
    apt_safe install -y "${to_install[@]}"
}

# Remove packages
apt_remove() {
    local packages=("$@")
    log_info "Removing packages: ${packages[*]}"
    apt_safe remove -y "${packages[@]}"
}

# Autoremove unused packages
apt_autoremove() {
    log_step "Removing unused packages..."
    apt_safe autoremove -y
}

# Clean apt cache
apt_clean() {
    log_step "Cleaning package cache..."
    apt_safe clean
}
