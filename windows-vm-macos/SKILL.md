---
name: windows-vm-macos
description: Set up a Windows 11 ARM VM on an Apple Silicon Mac with UTM, drive it from the CLI with utmctl, and keep a clean reset copy. Use when someone needs a Windows machine on macOS to test or try anything, such as builds, software, scripts, or behavior.
version: 1.0.0
---

# Windows 11 VM on macOS (UTM)

Apple Silicon only. Scripts live in `scripts/`; set `VM_NAME` (default `Windows`) to use another name.
Only `bash -n` checked: the guest helpers have not been run as scripts, so treat failures as bugs to fix.

## Stages
1. `scripts/01-preflight.sh`: checks arm64 and >= 80 GB free, installs UTM (`brew install --cask utm`).
2. **ISO (manual, GUI):** UTM > New > Virtualize > Windows > "Fetch latest Windows installer...", or CrystalFetch (Windows 11, Apple Silicon). About 5 GB, name contains `A64FRE`. Do not auto-run third-party download scripts.
3. `scripts/02-create-vm.sh`: **cannot create the VM**. UTM's wizard is GUI-only and its ISO picker is sandboxed. The script prints the settings, opens UTM, waits for the VM to appear, and starts it.
   Settings: **Virtualize**, Windows, tick "Install drivers and SPICE tools", 8192 MB, 4 CPUs, 64 GB, name `Windows`.
4. Install Windows by hand (gotchas below), then run the SPICE guest tools installer and reboot.
5. `scripts/03-wait-for-agent.sh`: polls `utmctl ip-address` until the guest agent answers.
6. `scripts/05-clean-reset.sh make` once Windows is installed; `CONFIRM=yes scripts/05-clean-reset.sh reset` wipes back to it.
7. `scripts/guest.sh run|ps|push|pull ...`: run commands in the guest and copy files to and from it.

## Gotchas
- **Virtualize, not Emulate.** The ISO is arm64; Emulate is for other architectures and is very slow.
- **Missed "Press any key to boot from CD"** drops you into the UEFI shell. Type `FS0:` (digit zero, not letter O), `cd efi\boot`, `bootaa64.efi`, then press a key immediately. Or power-cycle and tap space while booting.
- Choose **Windows 11 Pro**, "I don't have a product key", Custom install onto the unallocated disk. Unactivated is fine for testing.
- Stuck on a network/Microsoft-account screen: Shift+F10, run `OOBE\BYPASSNRO`, then choose "I don't have internet" after the restart.
- After first boot Windows runs about 15 minutes of updates; don't power off.
- `utmctl start` often prints `OSStatus error -2700` but the VM starts. Check `utmctl status`.
- `utmctl exec` can't capture stdout, and the guest agent runs as **SYSTEM**, not your user. `guest.sh` redirects to a file in `C:\Windows\Temp`, waits for a marker file, and pulls it.
- `utmctl snapshot create` fails ("Suspend is not supported when GPU acceleration is enabled"). Use stop + `utmctl clone` (done by `05-clean-reset.sh`). Alternative: switch the display device to `virtio-ramfb` in the GUI to enable snapshots.
- **Shared directories need the GUI.** UTM is sandboxed; the folder picker is in VM settings > Sharing (SPICE WebDAV, needs SPICE tools). WebDAV is bad for builds (slow, symlinks), so push a tarball with `guest.sh push` and build under `C:\src` instead.
- x64 Windows apps run on Windows 11 ARM via built-in emulation: fine for functional testing, not for performance.
