#!/usr/bin/env bash
# Quick verification: fstrim, SMART health, sensors, fstrim.timer.
# - LVM-aware: resolves the physical disk behind /
# - Uses smartctl -d nvme for NVMe devices

set -euo pipefail
IFS=$'\n\t'

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
need_sudo(){ [[ $EUID -ne 0 ]] && echo sudo || true; }

# Return the physical disk (e.g., /dev/nvme0n1 or /dev/sda) that backs /
backing_disk() {
  local src disk pk
  src="$(findmnt -no SOURCE / | xargs -r readlink -f || true)"
  [[ -z "${src:-}" ]] && src="/"

  # Walk child->parents and grab the first 'disk'
  disk="$(lsblk -s -no TYPE,PATH "$src" 2>/dev/null | awk '$1=="disk"{print $2; exit}')"
  if [[ -n "${disk:-}" ]]; then
    echo "$disk"
    return 0
  fi

  # Fallback via pkname of the source node
  pk="$(lsblk -no PKNAME "$src" 2>/dev/null | head -n1 || true)"
  if [[ -n "${pk:-}" ]]; then
    echo "/dev/$pk"
    return 0
  fi

  # As a last resort, prefer first NVMe node if present, else /dev/sda
  if command -v nvme >/dev/null 2>&1; then
    local first_nvme
    first_nvme="$(nvme list 2>/dev/null | awk 'NR>2 && $1 ~ /^\/dev\/nvme/ {print $1; exit}')"
    if [[ -n "${first_nvme:-}" ]]; then
      echo "$first_nvme"
      return 0
    fi
  fi

  echo "/dev/sda"
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
  local dev driver
  dev="$(backing_disk)"
  driver=""
  [[ "$(basename "$dev")" =~ ^nvme ]] && driver="-d nvme"
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
