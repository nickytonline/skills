#!/usr/bin/env bash
# Guest helpers. Usage:
#   guest.sh run  '<cmd.exe command line>'
#   guest.sh ps   '<powershell command>'
#   guest.sh push <local_file> <guest_path>
#   guest.sh pull <guest_path> [local_file]     (default: stdout)
# The guest agent runs as SYSTEM. Output is captured via a temp file in C:\Windows\Temp.
set -euo pipefail
cd "$(dirname "$0")" && . ./lib.sh
need utmctl
cmd="${1:-}"; shift || true
case "$cmd" in
  run)  guest_run "$1" ;;
  ps)   guest_ps "$1" ;;
  push) guest_push "$1" "$2" ;;
  pull) if [ -n "${2:-}" ]; then guest_pull "$1" > "$2"; else guest_pull "$1"; fi ;;
  *) sed -n '2,8p' "$0"; exit 2 ;;
esac
