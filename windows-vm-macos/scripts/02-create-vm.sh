#!/usr/bin/env bash
# Guide VM creation. UTM's wizard needs the GUI (and a sandboxed file picker for the ISO),
# so this script cannot create the VM; it prints the settings, opens UTM, and waits
# for the VM to show up in `utmctl list`, then starts it.
set -euo pipefail
cd "$(dirname "$0")" && . ./lib.sh
need utmctl

if vm_exists "$VM_NAME"; then
  echo "VM '$VM_NAME' already exists"
else
  cat <<MSG
Create the VM in UTM with these settings:
  Start:     Virtualize (NOT Emulate; the ISO is arm64)
  OS:        Windows. Tick "Install Windows 10 or higher" and "Install drivers and SPICE tools".
  Boot ISO:  Browse... to the Windows 11 ARM64 ISO
  Hardware:  8192 MB memory, 4 CPU cores
  Storage:   64 GB
  Name:      $VM_NAME   (use this exact name, or set VM_NAME for the other scripts)
Waiting for the VM to appear...
MSG
  open -a UTM
  until vm_exists "$VM_NAME"; do sleep 5; done
  echo "VM '$VM_NAME' created"
fi

if [ "$(vm_status "$VM_NAME")" != started ]; then
  # utmctl start often prints "OSStatus error -2700" yet the VM starts; check status instead.
  utmctl start "$VM_NAME" >/dev/null 2>&1 || true
  sleep 3
  [ "$(vm_status "$VM_NAME")" = started ] || die "VM did not start"
fi

cat <<'MSG'
Now install Windows in the UTM window (manual):
  - Press a key at "Press any key to boot from CD". If missed you land in the UEFI shell:
      FS0:            (digit zero, not the letter O)
      cd efi\boot
      bootaa64.efi    then press a key immediately
  - Edition: Windows 11 Pro. "I don't have a product key". Custom install onto the unallocated disk.
  - If it demands a network/Microsoft account: Shift+F10, run OOBE\BYPASSNRO, pick "I don't have internet" after the restart.
  - At the desktop, run the SPICE guest tools installer from the mounted drive, then reboot.
Then run 03-wait-for-agent.sh.
MSG
