#!/usr/bin/env bash
# Module: Remote Access Tools
# Installs OpenSSH (Server) and Remmina (Client)

set -euo pipefail

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Source library functions
if [[ -f "$LIB_DIR/logging.sh" ]]; then
    source "$LIB_DIR/logging.sh"
    source "$LIB_DIR/privileged.sh"
    source "$LIB_DIR/package.sh"
else
    echo "Library files not found in $LIB_DIR"
    exit 1
fi

# Default configuration
DRY_RUN="${DRY_RUN:-0}"
AUTO_YES="${AUTO_YES:-0}"

# Install OpenSSH Server
install_openssh() {
    log_step "Installing OpenSSH Server..."

    if command -v sshd >/dev/null 2>&1; then
        log_info "OpenSSH Server is already installed"
        return 0
    fi

    if (( DRY_RUN == 1 )); then
        log_info "[DRY RUN] Would install openssh-server, enable service, and allow UFW rule"
        return 0
    fi

    log_info "Installing openssh-server..."
    apt_install openssh-server

    log_info "Enabling SSH service..."
    run_privileged systemctl enable --now ssh

    # Configure firewall if UFW is active
    if command -v ufw >/dev/null 2>&1; then
        if run_privileged ufw status | grep -q "Status: active"; then
            log_info "Allowing SSH through firewall..."
            run_privileged ufw allow OpenSSH
        fi
    fi

    log_success "OpenSSH Server installed and enabled"
}

# Install Remmina
install_remmina() {
    log_step "Installing Remmina Remote Desktop Client..."

    if command -v remmina >/dev/null 2>&1; then
        log_info "Remmina is already installed"
        return 0
    fi

    if (( DRY_RUN == 1 )); then
        log_info "[DRY RUN] Would install remmina and plugins"
        return 0
    fi

    log_info "Installing Remmina + RDP/VNC plugins..."
    apt_install remmina remmina-plugin-rdp remmina-plugin-vnc remmina-plugin-spice

    log_success "Remmina installed"
}

# Main execution
main() {
    local install_ssh=0
    local install_remmina=0

    # Parse args
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --openssh)
                install_ssh=1
                shift
                ;;
            --remmina)
                install_remmina=1
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--openssh] [--remmina] [--dry-run]"
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done

    # Interactive mode if no args
    if (( install_ssh == 0 )) && (( install_remmina == 0 )); then
        echo "Select remote tools to install (y/n):"
        echo ""
        read -p "  OpenSSH Server (Secure terminal access)? [y/N] " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && install_ssh=1

        read -p "  Remmina (Remote Desktop Client)? [y/N] " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && install_remmina=1
    fi

    if (( install_ssh == 1 )); then
        install_openssh
    fi

    if (( install_remmina == 1 )); then
        install_remmina
    fi
}

# Run main if sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
