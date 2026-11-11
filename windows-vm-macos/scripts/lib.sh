#!/usr/bin/env bash
# Shared helpers. Source this file; do not execute it.
# Override the VM name with: VM_NAME=my-vm ./script.sh
VM_NAME="${VM_NAME:-Windows}"
CLEAN_NAME="${CLEAN_NAME:-${VM_NAME}-clean}"
GUEST_TMP='C:\Windows\Temp'

die() { echo "error: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing command: $1 (run 01-preflight.sh)"; }

vm_exists() { utmctl list 2>/dev/null | awk 'NR>1 {$1=$2=""; sub(/^ +/,""); print}' | grep -Fxq "$1"; }
vm_status() { utmctl status "$1" 2>/dev/null || echo "unknown"; }

# Run a cmd.exe command line in the guest as SYSTEM and print its combined output.
# utmctl exec cannot capture stdout, so redirect to a file, wait for a marker, then pull it.
# Returns the guest command's exit code.
guest_run() {
  local id out done rc
  id="winvm-$$-$RANDOM"
  out="$GUEST_TMP\\$id.out"
  done="$GUEST_TMP\\$id.done"
  utmctl exec "$VM_NAME" --cmd cmd.exe /v:on /c \
    "($1) > $out 2>&1 & echo !errorlevel! > $done" >/dev/null 2>&1 || true
  local i
  for i in $(seq 1 "${GUEST_TIMEOUT:-600}"); do
    if rc=$(utmctl file pull "$VM_NAME" "$done" 2>/dev/null); then break; fi
    sleep 1
    rc=""
  done
  [ -n "$rc" ] || die "timed out waiting for guest command: $1"
  utmctl file pull "$VM_NAME" "$out" 2>/dev/null | tr -d '\r\0' || true
  return "$(printf '%s' "$rc" | tr -dc '0-9' | sed 's/^$/1/')"
}

guest_ps() { guest_run "powershell -NoProfile -ExecutionPolicy Bypass -Command \"$1\""; }
guest_push() { utmctl file push "$VM_NAME" "$2" < "$1"; }   # local_file guest_path
guest_pull() { utmctl file pull "$VM_NAME" "$1"; }          # guest_path (stdout)

wait_for_agent() {
  local i
  for i in $(seq 1 "${AGENT_TIMEOUT:-1800}"); do
    if utmctl ip-address "$VM_NAME" 2>/dev/null | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'; then return 0; fi
    sleep 2
  done
  return 1
}
