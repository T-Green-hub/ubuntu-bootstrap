#!/usr/bin/env bash
# Quick verification: fstrim, SMART health, sensors, fstrim.timer.
# - LVM-aware: resolves the physical disk behind /
# - Uses smartctl -d nvme for NVMe devices when needed

set -euo pipefail
IFS=$'\n\t'

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
need_sudo(){ [[ $EUID -ne 0 ]] && echo sudo || true; }

# Return the block device (e.g., /dev/nvme0n1 or /dev/sda) that backs /
backing_disk() {
  local src phys
  src="$(findmnt -no SOURCE / | xargs -r readlink -f || true)"
  # If it's an LVM mapper path, resolve the physical parent
  phys="$(lsblk -no pkname "$src" 2>/dev/null | head -n1 || true)"
  if [[ -n "$phys" ]]; then
    echo "/dev/$phys"
    return 0
  fi
  # Fallback: parse basename and strip partition digits
  local base
  base="$(basename "${src:-/dev/nvme0n1}" | sed -E 's/p?[0-9]+$//')"
  [[ -n "$base" ]] && echo "/dev/$base" || echo "/dev/nvme0n1"
}

trim_root(){
  if ! command -v fstrim >/dev/null 2>&1; then
    log "fstrim not found."
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
  local dev driver arg
  dev="$(backing_disk)"
  driver=""
  # Prefer -d nvme when device looks like NVMe
  if [[ "$(basename "$dev")" =~ ^nvme ]]; then
    driver="-d nvme"
  fi
  log "SMART health for $dev…"
  if smartctl -H $driver "$dev"; then
    log "SMART health summary done."
  else
    log "SMART summary failed/unsupported."
  fi
}

nvme_brief(){
  if command -v nvme >/dev/null 2>&1; then
    log "NVMe list:"
    nvme list || true
  fi
}

sensors_brief(){
  if command -v sensors >/dev/null 2>&1; then
    log "Sensors snapshot:"
    sensors || true
  else
    log "lm-sensors not installed."
  fi
}

fstrim_timer_status(){
  log "fstrim.timer status:"
  systemctl list-timers fstrim.timer || true
}

main(){
  trim_root
  smart_check
  nvme_brief
  sensors_brief
  fstrim_timer_status
  log "Verification complete."
}

main "$@"
