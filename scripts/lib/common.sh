#!/usr/bin/env bash
# Common utilities for ubuntu-bootstrap
# Shared functions used across multiple modules

# Logging function with timestamp
log() {
    printf '[%s] %s\n' "$(date -Iseconds)" "$*"
}

# Returns "sudo" if not running as root, empty string otherwise
need_sudo() {
    if [[ $EUID -ne 0 ]]; then
        echo sudo
    fi
}

# Safe apt wrapper with lock handling and retries
apt_safe() {
    local max_attempts=6
    local attempt=0
    local wait_time=5
    
    while ((attempt < max_attempts)); do
        ((attempt++))
        
        # Check for dpkg/apt locks
        if $(need_sudo) fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
           $(need_sudo) fuser /var/lib/apt/lists/lock >/dev/null 2>&1; then
            if ((attempt < max_attempts)); then
                log "apt/dpkg locked, waiting ${wait_time}s (attempt $attempt/$max_attempts)..."
                sleep "$wait_time"
                continue
            else
                log "ERROR: apt/dpkg still locked after $max_attempts attempts"
                return 1
            fi
        fi
        
        # Execute apt command
        if $(need_sudo) apt-get "$@"; then
            return 0
        else
            local exit_code=$?
            if ((attempt < max_attempts)); then
                log "apt-get failed (exit $exit_code), retrying in ${wait_time}s (attempt $attempt/$max_attempts)..."
                sleep "$wait_time"
            else
                log "ERROR: apt-get failed after $max_attempts attempts"
                return $exit_code
            fi
        fi
    done
    
    return 1
}

# Backup a shell configuration file
backup_shell_file() {
    local file="$1"
    local backup_dir="$2"
    
    if [[ -f "$file" ]]; then
        local filename
        filename=$(basename "$file")
        cp "$file" "$backup_dir/$filename"
        log "[BACKUP] Saved $file to $backup_dir/$filename"
        return 0
    else
        log "[BACKUP] File not found: $file (skipping)"
        return 1
    fi
}

# Remove lines matching exact pattern from a file
remove_lines_from_file() {
    local file="$1"
    local pattern="$2"
    local backup_suffix="bak-$(date +%Y%m%d-%H%M%S)"
    
    if [[ ! -f "$file" ]]; then
        log "[CLEANUP] File not found: $file (skipping)"
        return 0
    fi
    
    # Create backup
    cp "$file" "${file}.${backup_suffix}"
    
    # Remove lines matching pattern (using | as delimiter to avoid issues with /)
    sed -i "\|${pattern}|d" "$file"
    
    log "[CLEANUP] Removed pattern from $file (backup: ${file}.${backup_suffix})"
    return 0
}

# Verify pattern is removed from file
verify_pattern_removed() {
    local file="$1"
    local pattern="$2"
    
    if [[ ! -f "$file" ]]; then
        return 0  # File doesn't exist, pattern can't be present
    fi
    
    if grep -qF "$pattern" "$file" 2>/dev/null; then
        log "[VERIFY] WARNING: Pattern still found in $file"
        return 1
    fi
    
    log "[VERIFY] Pattern successfully removed from $file"
    return 0
}

# Check if running in dry-run mode
is_dry_run() {
    [[ "${DRY_RUN:-0}" -eq 1 ]]
}

# Check if running in force mode (skip confirmations)
is_force_mode() {
    [[ "${FORCE:-0}" -eq 1 ]]
}

# Get timestamp for backups
get_timestamp() {
    date +%Y%m%d-%H%M%S
}

# Create backup directory
create_backup_dir() {
    local module="$1"
    local backup_dir="${2:-$HOME/.local/share/ubuntu-bootstrap/backups/${module}-$(get_timestamp)}"
    
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

# Confirmation prompt (respects FORCE and DRY_RUN)
confirm_action() {
    local message="$1"
    local default="${2:-N}"  # Y or N
    
    # Skip in dry-run mode
    if is_dry_run; then
        return 0
    fi
    
    # Skip in force mode
    if is_force_mode; then
        return 0
    fi
    
    # Show message and prompt
    echo ""
    echo "$message"
    
    local prompt
    if [[ "$default" == "Y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi
    
    read -p "Continue? $prompt " -n 1 -r
    echo ""
    
    if [[ "$default" == "Y" ]]; then
        [[ $REPLY =~ ^[Nn]$ ]] && return 1
        return 0
    else
        [[ $REPLY =~ ^[Yy]$ ]] || return 1
        return 0
    fi
}
