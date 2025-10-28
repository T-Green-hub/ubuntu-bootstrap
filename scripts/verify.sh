#!/usr/bin/env bash
set -euo pipefail
# Canonical verify entrypoint (used by CI and by `make verify`)
# It simply delegates to your existing 99_verify.sh.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "${SCRIPT_DIR}/99_verify.sh" "$@"
