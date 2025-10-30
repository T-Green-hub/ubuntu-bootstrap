#!/usr/bin/env bash
# Verification: fstrim, SMART health (NVMe-aware), sensors, fstrim.timer
# Ubuntu 24.04 — designed for LUKS+LVM on NVMe.
# Key fixes:
#  - Always use sudo for smartctl
#  - Resolve / → backing disk and NVMe controller (/dev/nvmeX)
#  - Try: auto → -d nvme on disk → -d nvme on controller
#  - Avoid stray spaces in "-d nvme" arg
set -euo pipefail
IFS=$'\n\t'

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then echo sudo; fi; }

# Resolve the physical disk that backs /
backing_disk() {
  local src disk pk
  src="$(findmnt -no SOURCE / | xargs -r readlink -f || true)"
  [[ -z "${src:-}" ]] && src="/"

  # Prefer walking up to the real "disk"
  disk="$(lsblk -s -no TYPE,PATH "$src" 2>/dev/null | awk '$1=="disk"{print $2; exit}')"
  if [[ -n "${disk:-}" ]]; then
    echo "$disk"
    return 0
  fi

  # Fallback: use PKNAME from the immediate node
  pk="$(lsblk -no PKNAME "$src" 2>/dev/null | head -n1 || true)"
  if [[ -n "${pk:-}" ]]; then
    echo "/dev/$pk"
    return 0
  fi

  # Last ditch: first NVMe, else sda
  if command -v nvme >/dev/null 2>&1; then
    local first_nvme
    first_nvme="$(nvme list 2>/dev/null | awk 'NR>2 && $1 ~ /^\/dev\/nvme/ {print $1; exit}')"
    [[ -n "${first_nvme:-}" ]] && { echo "$first_nvme"; return 0; }
  fi
  echo "/dev/sda"
}

# If /dev/nvme0n1 → /dev/nvme0 (controller), else return empty
nvme_controller_of() {
  local dev="$1" base
  base="$(basename "$dev")"
  if [[ "$base" =~ ^nvme([0-9]+)n([0-9]+)(p[0-9]+)?$ ]]; then
    echo "/dev/nvme${BASH_REMATCH[1]}"
  elif [[ "$base" =~ ^nvme([0-9]+)$ ]]; then
    echo "/dev/$base"
  else
    echo ""
  fi
}

trim_root(){
  if ! command -v fstrim >/dev/null 2>&1; then
    log "fstrim not found; skipping."
    return 0
  fi
  log "Running fstrim on / (root)…"
  if $(need_sudo) fstrim -v /; then
    log "fstrim OK."
  else
    log "fstrim failed (non-SSD or permissions?)."
  fi
}

smart_check(){
  if ! command -v smartctl >/dev/null 2>&1; then
    log "smartctl not installed (smartmontools). Skipping."
    return 0
  fi

  local disk ctrl rc=1
  disk="$(backing_disk)"
  ctrl="$(nvme_controller_of "$disk" || true)"

  log "SMART health for $disk…"

  # 1) Auto
  if $(need_sudo) smartctl -H "$disk"; then
    rc=0
  fi

  # 2) If still failing, try explicit nvme on the DISK path
  if (( rc != 0 )); then
    if $(need_sudo) smartctl -H -d nvme "$disk"; then
      rc=0
    fi
  fi

  # 3) If still failing and we have a controller path, try it
  if (( rc != 0 )) && [[ -n "${ctrl:-}" && "$ctrl" != "$disk" ]]; then
    if $(need_sudo) smartctl -H -d nvme "$ctrl"; then
      rc=0
    fi
  fi

  if (( rc != 0 )); then
    log "SMART summary failed/unsupported."
  fi
}

sensors_brief(){
  if ! command -v sensors >/dev/null 2>&1; then
    log "lm-sensors not installed; skipping sensors."
    return 0
  fi
  log "Sensors snapshot:"
  sensors || true
}

fstrim_timer(){
  log "fstrim.timer status:"
  systemctl list-timers fstrim.timer || true
}

nvme_list(){
  if command -v nvme >/dev/null 2>&1; then
    log "NVMe list:"
    nvme list || true
  fi
}

main(){
  trim_root
  smart_check
  sensors_brief
  nvme_list
  fstrim_timer
  # Optional: ProtonVPN quick status (if installed)
  if command -v protonvpn-app >/dev/null 2>&1; then
    log "ProtonVPN status:"
    if systemctl is-active --quiet me.proton.vpn.split_tunneling.service 2>/dev/null; then
      log "  ✓ Daemon running (me.proton.vpn.split_tunneling.service)"
    else
      log "  ⚠ Daemon not running (starts with GUI on first launch)"
    fi
    if systemctl is-enabled --quiet me.proton.vpn.split_tunneling.service 2>/dev/null; then
      log "  ✓ Service enabled"
    else
      log "  ⚠ Service not enabled"
    fi
  fi
  log "Verification complete."
}

main "$@"
