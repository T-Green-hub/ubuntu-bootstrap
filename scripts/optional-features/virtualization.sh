#!/usr/bin/env bash
# Module: Virtual Machine Management
# Installs VirtualBox or QEMU/KVM

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

# Install VirtualBox
install_virtualbox() {
    log_step "Installing VirtualBox..."

    if command -v virtualbox >/dev/null 2>&1; then
        log_info "VirtualBox is already installed"
        return 0
    fi

    if (( DRY_RUN == 1 )); then
        log_info "[DRY RUN] Would install virtualbox and extensions"
        return 0
    fi

    log_info "Installing VirtualBox (from Ubuntu repositories)..."
    apt_install virtualbox virtualbox-ext-pack virtualbox-guest-additions-iso

    # Add user to vboxusers group
    if ! groups "$USER" | grep -q vboxusers; then
        log_info "Adding user $USER to 'vboxusers' group..."
        run_privileged usermod -aG vboxusers "$USER"
        log_warning "You must log out and back in for group membership to take effect."
    fi

    log_success "VirtualBox installed"
}

# Install QEMU/KVM
install_qemu() {
    log_step "Installing QEMU/KVM High-Performance Virtualization..."

    if command -v virsh >/dev/null 2>&1; then
        log_info "Libvirt/KVM tools seem to be installed"
        return 0
    fi

    if (( DRY_RUN == 1 )); then
        log_info "[DRY RUN] Would install qemu-kvm, libvirt, and virt-manager"
        log_info "[DRY RUN] Would add user to libvirt/kvm groups"
        return 0
    fi

    # Check CPU virtualization support
    if ! grep -E -q '(vmx|svm)' /proc/cpuinfo; then
        log_warning "CPU virtualization support (VT-x/AMD-V) not detected."
        log_warning "KVM may not work efficiently."
    fi

    log_info "Installing KVM stack..."
    apt_install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager

    # Enable libvirtd
    log_info "Enabling libvirtd service..."
    run_privileged systemctl enable --now libvirtd

    # Add user to groups
    log_info "Adding user $USER to libvirt and kvm groups..."
    run_privileged usermod -aG libvirt "$USER" 2>/dev/null || true
    run_privileged usermod -aG kvm "$USER" 2>/dev/null || true

    log_warning "You must log out and back in for group membership to take effect."
    log_success "QEMU/KVM installed"
}

# Main execution
main() {
    local install_vbox=0
    local install_qemu=0

    # Parse args
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --virtualbox)
                install_vbox=1
                shift
                ;;
            --qemu)
                install_qemu=1
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--virtualbox] [--qemu] [--dry-run]"
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done

    # If no flags provided, ask interactively
    if (( install_vbox == 0 )) && (( install_qemu == 0 )); then
        echo "Select virtualization technology to install:"
        echo "  1) VirtualBox (Easy to use)"
        echo "  2) QEMU/KVM (High performance)"
        echo "  3) Cancel"
        echo ""
        read -p "Choice [1-3]: " -n 1 -r choice
        echo ""

        case "$choice" in
            1) install_vbox=1 ;;
            2) install_qemu=1 ;;
            *) exit 0 ;;
        esac
    fi

    if (( install_vbox == 1 )); then
        install_virtualbox
    fi

    if (( install_qemu == 1 )); then
        install_qemu
    fi
}

# Run main if sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
