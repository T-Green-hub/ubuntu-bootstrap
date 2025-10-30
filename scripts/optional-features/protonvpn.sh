#!/usr/bin/env bash
# ProtonVPN installation for Ubuntu 24.04
# Installs the official ProtonVPN app (daemon + GTK GUI).
# 
# Usage:
#   ./protonvpn.sh                    # Install ProtonVPN
#   DRY_RUN=1 ./protonvpn.sh          # Test without installing
#   source ./protonvpn.sh && uninstall_protonvpn  # Uninstall
#
# Documentation: ../docs/PROTONVPN.md

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hardware/common.sh"

log() { printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

install_protonvpn() {
    log "=== ProtonVPN Installation ==="
    log "Installing official ProtonVPN app (daemon + GUI)"
    log ""
    
    # Check if already installed (official GUI app)
    if command -v protonvpn-app >/dev/null 2>&1 || is_installed proton-vpn-gnome-desktop; then
        log "✓ ProtonVPN app already installed"
        log "  Launch with: protonvpn-app"
        return 0
    fi
    
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would install ProtonVPN repository and app"
        log "[DRY RUN] Steps:"
        log "[DRY RUN]   1. Add ProtonVPN GPG key"
        log "[DRY RUN]   2. Add ProtonVPN repository"
        log "[DRY RUN]   3. Install proton-vpn-gnome-desktop"
        return 0
    fi
    
    # Check internet connectivity before proceeding
    if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        log "ERROR: No internet connection. Cannot download ProtonVPN."
        log "       Please connect to the internet and try again."
        return 1
    fi
    
    log "Step 1/3: Configuring ProtonVPN repository..."
    log ""

    # Always refresh ProtonVPN repository key to avoid NO_PUBKEY issues
    local keyring_path="/usr/share/keyrings/proton-vpn-stable-archive-keyring.gpg"
    local key_url_primary="https://repo.protonvpn.com/debian/public_key.asc"
    local key_url_alt="https://repo.protonvpn.com/debian/dists/stable/public_key.asc"
    
    log "  → Adding ProtonVPN GPG key..."
    local key_success=0
    
    if wget -qO- "$key_url_primary" 2>/dev/null | $(need_sudo) gpg --batch --yes --dearmor -o "$keyring_path" 2>/dev/null; then
        log "  ✓ ProtonVPN keyring installed: $keyring_path"
        key_success=1
    else
        log "  ⚠ Primary key URL failed, trying alternate..."
        if wget -qO- "$key_url_alt" 2>/dev/null | $(need_sudo) gpg --batch --yes --dearmor -o "$keyring_path" 2>/dev/null; then
            log "  ✓ ProtonVPN keyring installed (alternate URL): $keyring_path"
            key_success=1
        else
            log "  ✗ ERROR: Failed to fetch ProtonVPN key from both URLs"
            log "    Primary: $key_url_primary"
            log "    Alternate: $key_url_alt"
            log "    This may cause apt update to fail."
            log ""
            log "  Troubleshooting:"
            log "    - Check internet connection: ping repo.protonvpn.com"
            log "    - Try manual key download: wget $key_url_primary"
            return 1
        fi
    fi
    
    log ""
    log "Step 2/3: Adding ProtonVPN repository..."
    
    # Add repository if not already present
    local repo_file="/etc/apt/sources.list.d/protonvpn-stable.list"
    if [[ ! -f "$repo_file" ]]; then
        echo "deb [signed-by=/usr/share/keyrings/proton-vpn-stable-archive-keyring.gpg] https://repo.protonvpn.com/debian stable main" | \
            $(need_sudo) tee "$repo_file" >/dev/null
        log "  ✓ ProtonVPN repository added: $repo_file"
    else
        log "  ✓ ProtonVPN repository already configured"
    fi
    
    log ""
    log "  → Updating package lists..."
    
    # Update package list (retry once if it fails due to key issues)
    if ! apt_safe update -qq; then
        log "  ⚠ First apt update failed; attempting key refresh and retry..."
        if wget -qO- "$key_url_primary" 2>/dev/null | $(need_sudo) gpg --batch --yes --dearmor -o "$keyring_path" 2>/dev/null || \
           wget -qO- "$key_url_alt" 2>/dev/null | $(need_sudo) gpg --batch --yes --dearmor -o "$keyring_path" 2>/dev/null; then
            log "  → Key refreshed; retrying apt update..."
            if ! apt_safe update -qq; then
                log "  ✗ ERROR: apt update failed after key refresh"
                log "    Run manually: sudo apt update"
                return 1
            fi
        else
            log "  ✗ ERROR: Could not refresh key or update package lists"
            return 1
        fi
    fi
    log "  ✓ Package lists updated"
    
    log ""
    log "Step 3/3: Installing ProtonVPN packages..."
    log "  → Installing proton-vpn-gnome-desktop (this may take a few minutes)..."
    
    # Install ProtonVPN official app (daemon + GTK GUI)
    if ! apt_safe install -y proton-vpn-gnome-desktop; then
        log "  ✗ ERROR: Failed to install ProtonVPN"
        log "    Try manually: sudo apt install -y proton-vpn-gnome-desktop"
        return 1
    fi
    
    log "  ✓ ProtonVPN installed successfully"
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "✓ ProtonVPN Installation Complete"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log ""
    log "Next Steps:"
    log "  1. Launch ProtonVPN: protonvpn-app"
    log "     (Or find 'Proton VPN' in Applications menu)"
    log "  2. Sign in with your Proton account"
    log "  3. Connect to a VPN server"
    log ""
    log "Documentation: docs/PROTONVPN.md"
    log "Service status: systemctl status me.proton.vpn.split_tunneling.service"
    log ""
    log "Note: The legacy community CLI (protonvpn-cli) is NOT included."
    log "      For headless/server usage, see docs/PROTONVPN.md"
    log ""
}

verify_protonvpn() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would verify ProtonVPN installation"
        return 0
    fi
    
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Verifying ProtonVPN Installation"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log ""
    
    local errors=0
    
    # Check GUI application
    if command -v protonvpn-app >/dev/null 2>&1; then
        log "✓ ProtonVPN GUI available (protonvpn-app)"
    else
        log "✗ ProtonVPN GUI not found in PATH"
        errors=$((errors + 1))
    fi
    
    # Check if package is installed
    if is_installed proton-vpn-gnome-desktop; then
        log "✓ Package proton-vpn-gnome-desktop installed"
    else
        log "✗ Package proton-vpn-gnome-desktop not installed"
        errors=$((errors + 1))
    fi
    
    # Check daemon service
    if systemctl is-active --quiet me.proton.vpn.split_tunneling.service 2>/dev/null; then
        log "✓ ProtonVPN daemon service running"
    else
        log "⚠ ProtonVPN daemon service not running (will start on first launch)"
    fi
    
    # Check if service is enabled
    if systemctl is-enabled --quiet me.proton.vpn.split_tunneling.service 2>/dev/null; then
        log "✓ ProtonVPN daemon service enabled"
    else
        log "⚠ ProtonVPN daemon service not enabled"
    fi
    
    # Check for legacy CLI (informational only)
    if command -v protonvpn-cli >/dev/null 2>&1; then
        log "ℹ Legacy ProtonVPN CLI detected (separate installation)"
    fi
    
    log ""
    if (( errors == 0 )); then
        log "✓ All checks passed!"
        log ""
        return 0
    else
        log "✗ Verification failed with $errors error(s)"
        log "  Run: sudo bash scripts/optional-features/protonvpn.sh"
        log ""
        return 1
    fi
}

uninstall_protonvpn() {
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "ProtonVPN Uninstallation"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log ""
    
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would perform the following:"
        log "[DRY RUN]   1. Stop ProtonVPN daemon service"
        log "[DRY RUN]   2. Disable ProtonVPN daemon service"
        log "[DRY RUN]   3. Remove packages: proton-vpn-gnome-desktop proton-vpn-gtk-app proton-vpn-daemon"
        log "[DRY RUN]   4. Remove repository: /etc/apt/sources.list.d/protonvpn-stable.list"
        log "[DRY RUN]   5. Remove keyring: /usr/share/keyrings/proton-vpn-stable-archive-keyring.gpg"
        log "[DRY RUN]   6. Update package lists"
        return 0
    fi

    log "Step 1/4: Stopping ProtonVPN services..."
    if systemctl is-active --quiet me.proton.vpn.split_tunneling.service 2>/dev/null; then
        $(need_sudo) systemctl stop me.proton.vpn.split_tunneling.service 2>/dev/null || true
        log "  ✓ ProtonVPN daemon stopped"
    else
        log "  → Service not running (skipped)"
    fi

    log ""
    log "Step 2/4: Disabling ProtonVPN services..."
    if systemctl is-enabled --quiet me.proton.vpn.split_tunneling.service 2>/dev/null; then
        $(need_sudo) systemctl disable me.proton.vpn.split_tunneling.service 2>/dev/null || true
        log "  ✓ ProtonVPN daemon disabled"
    else
        log "  → Service not enabled (skipped)"
    fi

    log ""
    log "Step 3/4: Removing ProtonVPN packages..."
    if apt_safe remove -y proton-vpn-gnome-desktop proton-vpn-gtk-app proton-vpn-daemon 2>/dev/null; then
        log "  ✓ ProtonVPN packages removed"
    else
        log "  ⚠ Some packages may not have been installed"
    fi

    log ""
    log "Step 4/4: Cleaning up repository configuration..."
    $(need_sudo) rm -f /etc/apt/sources.list.d/protonvpn-stable.list
    $(need_sudo) rm -f /usr/share/keyrings/proton-vpn-stable-archive-keyring.gpg
    log "  ✓ Repository and keyring removed"
    
    log ""
    log "  → Updating package lists..."
    apt_safe update -qq
    log "  ✓ Package lists updated"
    
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "✓ ProtonVPN Uninstalled Successfully"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log ""
}

main() {
    install_protonvpn
    local install_status=$?
    
    if (( install_status == 0 )); then
        verify_protonvpn
    else
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "✗ ProtonVPN Installation Failed"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log ""
        log "Troubleshooting:"
        log "  1. Check internet connection: ping -c 3 repo.protonvpn.com"
        log "  2. Verify repository access: curl -I https://repo.protonvpn.com/debian/public_key.asc"
        log "  3. Check apt logs: tail -n 50 /var/log/apt/term.log"
        log "  4. See documentation: docs/PROTONVPN.md"
        log ""
        return 1
    fi
}

# Allow sourcing for functions or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
