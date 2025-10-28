#!/usr/bin/env bash
# Verification: fstrim, SMART health, sensors, fstrim.timer (Ubuntu 24.04)
# NVMe-safe SMART: try auto, then -d nvme, then -d nvme,1 (no stray spaces)

set -euo pipefail
IFS=$'\n\t'

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
need_sudo(){ [[ $EUID -ne 0 ]] && echo sudo || true; }

backing_disk() {
  # Resolve the physical disk that backs /
  local src disk pk
  src="$(findmnt -no SOURCE / | xargs -r readlink -f || true)"
  [[ -z "${src:-}" ]] && src="/"
  disk="$(lsblk -s -no TYPE,PATH "$src" 2>/dev/null | awk '$1=="disk"{print $2; exit}')"
  if [[ -n "${disk:-}" ]]; then echo "$disk"; return 0; fi
  pk="$(lsblk -no PKNAME "$src" 2>/dev/null | head -n1 || true)"
  if [[ -n "${pk:-}" ]]; then echo "/dev/$pk"; return 0; fi
  if command -v nvme >/dev/null 2>&1; then
    local first_nvme
    first_nvme="$(nvme list 2>/dev/null | awk 'NR>2 && $1 ~ /^\/dev\/nvme/ {print $1; exit}')"
    [[ -n "${first_nvme:-}" ]] && { echo "$first_nvme"; return 0; }
  fi
  echo "/dev/sda"
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
  local dev rc=1
  dev="$(backing_disk)"
  log "SMART health for $dev…"

  # try auto
  if smartctl -H "$dev"; then rc=0; fi

  # if auto failed, try NVMe variants explicitly (no leading spaces)
  if (( rc != 0 )); then
    if smartctl -H -d nvme "$dev"; then rc=0; fi
  fi
  if (( rc != 0 )); then
    if smartctl -H -d nvme,1 "$dev"; then rc=0; fi
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

main(){
  trim_root
  smart_check
  sensors_brief
  fstrim_timer
  log "Verification complete."
}

main "$@"
