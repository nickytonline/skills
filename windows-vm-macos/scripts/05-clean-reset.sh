#!/usr/bin/env bash
# Reset point via clone. `utmctl snapshot create` fails here with
# "Suspend is not supported when GPU acceleration is enabled", so use stop + clone.
#   05-clean-reset.sh make    shut down VM, clone it to ${VM_NAME}-clean, start it again
#   05-clean-reset.sh reset   DELETE VM_NAME, re-clone from the clean copy, start it
set -euo pipefail
cd "$(dirname "$0")" && . ./lib.sh
need utmctl

stop_vm() {
  utmctl stop "$VM_NAME" >/dev/null 2>&1 || true
  local i
  for i in $(seq 1 60); do [ "$(vm_status "$VM_NAME")" = stopped ] && return 0; sleep 5; done
  die "VM did not stop"
}
start_vm() { utmctl start "$VM_NAME" >/dev/null 2>&1 || true; sleep 3; }

case "${1:-}" in
  make)
    vm_exists "$CLEAN_NAME" && die "'$CLEAN_NAME' already exists; delete it first to re-make"
    stop_vm
    utmctl clone "$VM_NAME" --name "$CLEAN_NAME"
    start_vm
    echo "clean copy: $CLEAN_NAME" ;;
  reset)
    vm_exists "$CLEAN_NAME" || die "no '$CLEAN_NAME'; run '$0 make' on a fresh install first"
    echo "Deleting '$VM_NAME' and re-cloning from '$CLEAN_NAME' (no confirmation in utmctl)"
    [ "${CONFIRM:-}" = yes ] || die "set CONFIRM=yes to proceed"
    stop_vm
    utmctl delete "$VM_NAME"
    utmctl clone "$CLEAN_NAME" --name "$VM_NAME"
    start_vm
    wait_for_agent || die "guest agent did not come up after reset" ;;
  *) sed -n '2,6p' "$0"; exit 2 ;;
esac
