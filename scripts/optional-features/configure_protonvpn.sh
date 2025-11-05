#!/usr/bin/env bash
# ProtonVPN Post-Install Configuration Helper
# Assists with setting up auto-connect for free servers
#
# Usage:
#   ./configure_protonvpn.sh          # Interactive setup
#   ./configure_protonvpn.sh --help   # Show help

set -euo pipefail

log() { printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

show_help() {
    cat <<'EOF'
ProtonVPN Configuration Helper
==============================

This script helps configure ProtonVPN for optimal use:
- Auto-connect to VPN on system start
- Background daemon for persistent connection
- System tray icon for easy access

IMPORTANT: This is a HELPER script. ProtonVPN requires manual login
through the GUI for security reasons (we don't handle credentials).

Prerequisites:
  1. ProtonVPN must be installed
  2. You need a Proton account (Free tier works!)
  3. You must log in through the GUI first

What this script does:
  - Verifies ProtonVPN installation
  - Enables the ProtonVPN daemon service
  - Provides step-by-step instructions for GUI setup
  - Configures system tray behavior
  - Tests the configuration

What you must do manually:
  - Log in through ProtonVPN GUI (one-time)
  - Select a free server (Netherlands, US, Japan are usually free)
  - Enable auto-connect in app settings

Free Tier Notes:
  - Free tier includes servers in 3 countries (varies by region)
  - Medium speed, single device
  - No P2P, no streaming services
  - Perfect for privacy and security

Usage:
  ./configure_protonvpn.sh          # Run interactive setup
  ./configure_protonvpn.sh --help   # Show this help

EOF
}

verify_protonvpn_installed() {
    log "=== Verifying ProtonVPN Installation ==="
    
    if ! command -v protonvpn-app >/dev/null 2>&1; then
        log "✗ ProtonVPN is not installed"
        log ""
        log "Install it first:"
        log "  cd /home/tg/ubuntu-bootstrap-1"
        log "  sudo bash scripts/optional-features/protonvpn.sh"
        log ""
        return 1
    fi
    
    log "✓ ProtonVPN GUI found"
    
    if ! dpkg -s proton-vpn-gnome-desktop >/dev/null 2>&1; then
        log "⚠ Package proton-vpn-gnome-desktop not found"
        log "  This may indicate an incomplete installation"
        return 1
    fi
    
    log "✓ ProtonVPN package installed"
    
    return 0
}

enable_daemon_service() {
    log ""
    log "=== Configuring ProtonVPN Daemon ==="
    
    local service="me.proton.vpn.split_tunneling.service"
    
    # Check if service exists
    if ! systemctl list-unit-files | grep -q "$service"; then
        log "⚠ ProtonVPN service not found"
        log "  The service will be created on first GUI launch"
        return 0
    fi
    
    # Enable service
    if systemctl is-enabled --quiet "$service" 2>/dev/null; then
        log "✓ ProtonVPN daemon already enabled"
    else
        log "→ Enabling ProtonVPN daemon..."
        sudo systemctl enable "$service" 2>/dev/null || {
            log "⚠ Could not enable service (may not be created yet)"
            log "  This is normal before first launch"
            return 0
        }
        log "✓ ProtonVPN daemon enabled"
    fi
    
    # Check if running
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        log "✓ ProtonVPN daemon is running"
    else
        log "→ ProtonVPN daemon not running (will start on first connection)"
    fi
    
    return 0
}

show_gui_setup_instructions() {
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "MANUAL SETUP REQUIRED (One-Time Only)"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log ""
    log "Step 1: Launch ProtonVPN"
    log "  Run: protonvpn-app"
    log "  Or: Open Applications → Proton VPN"
    log ""
    log "Step 2: Log In (One-Time)"
    log "  - Enter your Proton account email"
    log "  - Enter your password"
    log "  - Complete 2FA if enabled"
    log ""
    log "Step 3: Connect to a FREE Server"
    log "  Free servers are marked with 'FREE' badge"
    log "  Typical free countries:"
    log "    • Netherlands (NL)"
    log "    • United States (US)"
    log "    • Japan (JP)"
    log "  "
    log "  AVOID paid-only servers (will show upgrade prompt)"
    log ""
    log "Step 4: Enable Auto-Connect"
    log "  1. Click hamburger menu (☰) → Settings"
    log "  2. Go to 'Connection' tab"
    log "  3. Enable 'Auto-connect'"
    log "  4. Select 'Quick Connect' or a specific free server"
    log "  5. Enable 'Start minimized' (optional, keeps in tray)"
    log ""
    log "Step 5: Enable Kill Switch (Recommended)"
    log "  1. Settings → Connection"
    log "  2. Enable 'Kill Switch'"
    log "  3. This prevents IP leaks if VPN disconnects"
    log ""
    log "Step 6: Configure System Tray"
    log "  - The app will minimize to system tray"
    log "  - Closing the window keeps the connection active"
    log "  - Click tray icon to reopen or disconnect"
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log ""
}

test_configuration() {
    log "=== Testing Configuration ==="
    log ""
    
    # Check if user is logged in (config file exists)
    local config_dir="$HOME/.config/protonvpn"
    if [[ -d "$config_dir" ]]; then
        log "✓ ProtonVPN config directory exists"
    else
        log "⚠ ProtonVPN config not found (you haven't logged in yet)"
        log "  Launch protonvpn-app and log in first"
        return 0
    fi
    
    # Check for session file (indicates logged in)
    if [[ -f "$config_dir/app_config.json" ]] || [[ -f "$config_dir/settings.json" ]]; then
        log "✓ ProtonVPN appears to be configured"
    else
        log "⚠ No active session found"
        log "  Log in through the GUI to complete setup"
    fi
    
    log ""
    log "To verify VPN is working after connection:"
    log "  curl https://ipinfo.io/ip"
    log "  (Should show ProtonVPN server IP, not your real IP)"
    log ""
}

add_to_autostart() {
    log "=== Configuring Autostart ==="
    log ""
    
    local autostart_dir="$HOME/.config/autostart"
    local desktop_file="$autostart_dir/protonvpn-app.desktop"
    
    mkdir -p "$autostart_dir"
    
    if [[ -f "$desktop_file" ]]; then
        log "✓ ProtonVPN already in autostart"
        return 0
    fi
    
    # Create autostart entry
    cat > "$desktop_file" <<'EOF'
[Desktop Entry]
Type=Application
Name=Proton VPN
Comment=Connect to ProtonVPN on startup
Exec=protonvpn-app --minimized
Icon=protonvpn
Terminal=false
Categories=Network;
X-GNOME-Autostart-enabled=true
EOF
    
    log "✓ Added ProtonVPN to autostart (will launch minimized)"
    log "  Location: $desktop_file"
    log ""
    log "  ProtonVPN will now start automatically on login"
    log "  (Requires auto-connect to be enabled in app settings)"
    log ""
}

main() {
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "ProtonVPN Configuration Helper"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log ""
    
    # Verify installation
    if ! verify_protonvpn_installed; then
        exit 1
    fi
    
    # Enable daemon
    enable_daemon_service
    
    # Add to autostart
    add_to_autostart
    
    # Show manual setup instructions
    show_gui_setup_instructions
    
    # Test current state
    test_configuration
    
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "✓ Configuration Helper Complete"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log ""
    log "Next Steps:"
    log "  1. Run: protonvpn-app"
    log "  2. Follow the setup instructions above"
    log "  3. Your connection will persist even after closing the GUI"
    log "  4. Auto-connect will work on next login (after GUI setup)"
    log ""
    log "Documentation: docs/PROTONVPN.md"
    log ""
}

main "$@"
