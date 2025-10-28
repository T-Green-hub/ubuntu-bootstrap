#!/usr/bin/env bash
# Quick verification: fstrim, SMART health, sensors, fstrim.timer.

set -euo pipefail
IFS=$'\n\t'

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
need_sudo(){ [[ $EUID -ne 0 ]] && echo sudo || true; }

primary_block(){
  local rootdev blk
  rootdev="$(findmnt -no SOURCE / || true)"
  blk="$(basename "$rootdev" | sed -E 's/p?[0-9]+$//')"
  [[ -z "$blk" ]] && blk="nvme0n1"
  echo "/dev/$blk"
}

trim_root(){
  command -v fstrim >/dev/null 2>&1 || { log "fstrim not found."; return 0; }
  log "Running fstrim on / (root)…"
  $(need_sudo) fstrim -v / || log "fstrim failed (non-SSD/perm?)."
}

smart_check(){
  command -v smartctl >/dev/null 2>&1 || { log "smartctl not installed."; return 0; }
  local dev; dev="$(primary_block)"
  log "SMART health for $dev…"
  smartctl -H "$dev" || log "SMART summary failed/unsupported."
}

nvme_brief(){ command -v nvme >/dev/null 2>&1 && { log "NVMe list:"; nvme list || true; }; }
sensors_brief(){ command -v sensors >/dev/null 2>&1 && { log "Sensors:"; sensors || true; } || log "lm-sensors not installed."; }
fstrim_timer(){ log "fstrim.timer status:"; systemctl list-timers fstrim.timer || true; }

main(){ trim_root; smart_check; nvme_brief; sensors_brief; fstrim_timer; log "Verification complete."; }
main "$@"
