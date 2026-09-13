#!/usr/bin/env bash
set -euo pipefail

if command -v mergiraf >/dev/null 2>&1; then
  echo "mergiraf is already installed: $(command -v mergiraf)"
  mergiraf --version
  exit 0
fi

if command -v brew >/dev/null 2>&1; then
  echo "Installing mergiraf with Homebrew..."
  brew install mergiraf
elif command -v cargo >/dev/null 2>&1; then
  echo "Installing mergiraf with Cargo..."
  cargo install mergiraf
else
  echo "Unable to install mergiraf automatically: neither Homebrew nor Cargo is available." >&2
  echo "See https://mergiraf.org/ for installation options." >&2
  exit 1
fi

if ! command -v mergiraf >/dev/null 2>&1; then
  echo "mergiraf installation completed but the binary is not available on PATH." >&2
  exit 1
fi

mergiraf --version
