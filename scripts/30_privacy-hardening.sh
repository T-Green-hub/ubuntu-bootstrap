#!/usr/bin/env bash
# Ubuntu 24.04 privacy hardening and security (idempotent).
# Disable telemetry, enable firewall, secure DNS, minimize services.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../hardware/common.sh"

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then echo sudo; fi; }

# Disable Ubuntu telemetry and reporting
disable_telemetry(){
  log "Disabling Ubuntu telemetry…"

  # Ubuntu report (popularity contest)
  if command -v ubuntu-report >/dev/null 2>&1; then
    log "Disabling ubuntu-report…"
    ubuntu-report -f send no || true
  fi

  # Popularity contest
  if dpkg -s popularity-contest >/dev/null 2>&1; then
    log "Removing popularity-contest…"
    $(need_sudo) apt-get purge -y popularity-contest 2>/dev/null || true
  fi

  # Apport (crash reporting)
  if systemctl is-enabled apport.service >/dev/null 2>&1; then
    log "Disabling apport crash reporting…"
    $(need_sudo) systemctl disable apport.service
    $(need_sudo) systemctl stop apport.service 2>/dev/null || true
  fi

  # Also disable via config
  local apport_conf="/etc/default/apport"
  if [[ -f "$apport_conf" ]]; then
    if grep -q "^enabled=1" "$apport_conf"; then
      log "Updating apport config…"
      $(need_sudo) sed -i 's/^enabled=1/enabled=0/' "$apport_conf"
    fi
  fi

  log "Telemetry disabled."
}

# Setup and enable UFW firewall
setup_firewall(){
  if ! command -v ufw >/dev/null 2>&1; then
    log "Installing UFW firewall…"
    apt_safe update -qq
    apt_safe install -y ufw
  fi

  log "Configuring UFW firewall…"

  # Set default policies
  $(need_sudo) ufw --force default deny incoming
  $(need_sudo) ufw --force default allow outgoing

  # Allow SSH (important!)
  $(need_sudo) ufw allow ssh

  # Enable firewall
  if $(need_sudo) ufw status | grep -q "Status: active"; then
    log "UFW already active."
  else
    log "Enabling UFW…"
    $(need_sudo) ufw --force enable
  fi

  log "Firewall configured: deny incoming (except SSH), allow outgoing."
}

# Disable unnecessary services for privacy/security
disable_unnecessary_services(){
  log "Checking for unnecessary services…"

  # Avahi (mDNS/Bonjour) - broadcasts hostname on network
  if systemctl is-enabled avahi-daemon.service >/dev/null 2>&1; then
    log "Disabling avahi-daemon (network broadcasting)…"
    $(need_sudo) systemctl disable avahi-daemon.service
    $(need_sudo) systemctl stop avahi-daemon.service 2>/dev/null || true
  fi

  # CUPS (printing) - only disable if no printers
  if systemctl is-enabled cups.service >/dev/null 2>&1; then
    log "Note: CUPS print service is running. Disable manually if no printer needed:"
    log "  sudo systemctl disable cups.service"
  fi

  log "Service review complete."
}

# DNS hardening (systemd-resolved with secure defaults)
harden_dns(){
  log "Configuring secure DNS settings…"

  local resolved_conf="/etc/systemd/resolved.conf.d/privacy.conf"

  if [[ -f "$resolved_conf" ]]; then
    log "DNS config already exists: $resolved_conf"
    return 0
  fi

  $(need_sudo) mkdir -p /etc/systemd/resolved.conf.d

  cat <<'EOF' | $(need_sudo) tee "$resolved_conf" >/dev/null
# Privacy-focused DNS configuration
[Resolve]
DNS=1.1.1.1 9.9.9.9
FallbackDNS=1.0.0.1 8.8.8.8
#DNSOverTLS=yes
DNSSEC=allow-downgrade
DNSStubListener=yes
EOF

  log "DNS configuration created. Restarting systemd-resolved…"
  $(need_sudo) systemctl restart systemd-resolved || true

  log "DNS hardening complete (Cloudflare 1.1.1.1, Quad9 9.9.9.9)."
}

# Additional privacy tweaks
additional_privacy(){
  log "Applying additional privacy settings…"

  # Disable system error reports
  if [[ -d /var/crash ]]; then
    log "Cleaning /var/crash…"
    # Multiple safety checks for critical system path
    local crash_path="/var/crash"
    if [[ "$(readlink -f "$crash_path")" == "$crash_path" ]]; then
      # Additional validation - path must be exactly /var/crash
      if [[ "$crash_path" != "/var/crash" ]]; then
        log "ERROR: Unexpected crash path: $crash_path"
        return 1
      fi
      # Only clean contents, not the directory itself
      if ! $(need_sudo) find /var/crash -mindepth 1 -delete 2>/dev/null; then
        log "WARNING: Could not clean /var/crash contents (may be empty or permission issue)"
      fi
    fi
  fi

  # Disable whoopsie (Ubuntu error reporting daemon)
  if systemctl is-enabled whoopsie.service >/dev/null 2>&1; then
    log "Disabling whoopsie error reporting…"
    $(need_sudo) systemctl disable whoopsie.service
    $(need_sudo) systemctl stop whoopsie.service 2>/dev/null || true
  fi

  log "Additional privacy tweaks applied."
}

# Verification
verify_hardening(){
  log "Verifying privacy/security configuration…"

  # Check firewall
  if $(need_sudo) ufw status | grep -q "Status: active"; then
    log "✓ UFW firewall: ACTIVE"
  else
    log "✗ UFW firewall: INACTIVE"
  fi

  # Check apport
  if systemctl is-active apport.service >/dev/null 2>&1; then
    log "⚠ Apport still running"
  else
    log "✓ Apport: disabled"
  fi

  # Check DNS
  if [[ -f /etc/systemd/resolved.conf.d/privacy.conf ]]; then
    log "✓ DNS hardening: configured"
  fi
}

main(){
  log "=== Privacy Hardening & Security ==="
  disable_telemetry
  setup_firewall
  disable_unnecessary_services
  harden_dns
  additional_privacy
  verify_hardening
  log "Privacy hardening complete."
}

main "$@"
