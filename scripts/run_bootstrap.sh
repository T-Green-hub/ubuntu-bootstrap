#!/usr/bin/env bash
# Minimal end-to-end bootstrap runner (idempotent).
# Runs base packages, then verification.

set -euo pipefail
IFS=$'\n\t'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

log "1/2 base packages…"
bash "$REPO_DIR/scripts/10_base-packages.sh"

log "2/2 verification…"
bash "$REPO_DIR/scripts/99_verify.sh"

log "bootstrap run complete."
