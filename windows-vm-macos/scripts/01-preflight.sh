#!/usr/bin/env bash
# Check the host and install UTM. Idempotent.
set -euo pipefail
cd "$(dirname "$0")" && . ./lib.sh

[ "$(uname -s)" = Darwin ] || die "macOS only"
[ "$(uname -m)" = arm64 ] || die "Apple Silicon required (this uses the Windows 11 ARM image with Virtualize)"
need brew

free_gb=$(df -g / | awk 'NR==2 {print $4}')
[ "$free_gb" -ge 80 ] || die "need >= 80 GB free, have ${free_gb} GB"

if [ -d /Applications/UTM.app ]; then echo "UTM already installed"; else brew install --cask utm; fi
need utmctl

cat <<'MSG'

Next, get the Windows 11 ARM64 ISO (manual, needs a GUI):
  - In UTM: New (+) > Virtualize > Windows > "Fetch latest Windows installer...", or
  - CrystalFetch (brew install --cask crystalfetch): Windows 11, Apple Silicon, English, edition Windows 11.
The ISO is ~5 GB and its name contains A64FRE. Then run 02-create-vm.sh.
MSG
