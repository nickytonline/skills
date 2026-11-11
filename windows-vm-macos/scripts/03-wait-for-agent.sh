#!/usr/bin/env bash
# Block until the QEMU guest agent answers (needs SPICE/guest tools installed in Windows).
set -euo pipefail
cd "$(dirname "$0")" && . ./lib.sh
need utmctl
vm_exists "$VM_NAME" || die "no VM named '$VM_NAME'"
wait_for_agent || die "guest agent never came up (are the SPICE guest tools installed?)"
utmctl ip-address "$VM_NAME" | head -1
guest_run "ver & hostname"
