#!/bin/bash
# Tzuron pull script for Linux AMD64

set -euo pipefail

echo "Fetching Tzuron amd64 installer from Releases..."

TMP_SCRIPT="$(mktemp /tmp/tzuron_install_amd64.XXXXXX.sh)"
RELEASE_URL="https://github.com/TRONIC-B-21/Tzuron-udp/releases/latest/download/install_tzuron_amd64.sh"

if command -v curl >/dev/null 2>&1; then
  if ! curl -fL "$RELEASE_URL" | sed 's/\r$//' > "$TMP_SCRIPT"; then
    echo "Falling back to main branch installer..."
    curl -fsSL "https://raw.githubusercontent.com/TRONIC-B-21/Tzuron-udp/main/install_tzuron_amd64.sh" | sed 's/\r$//' > "$TMP_SCRIPT"
  fi
elif command -v wget >/dev/null 2>&1; then
  if ! wget -qO- "$RELEASE_URL" | sed 's/\r$//' > "$TMP_SCRIPT"; then
    echo "Falling back to main branch installer..."
    wget -qO- "https://raw.githubusercontent.com/TRONIC-B-21/Tzuron-udp/main/install_tzuron_amd64.sh" | sed 's/\r$//' > "$TMP_SCRIPT"
  fi
else
  echo "Error: curl or wget is required to download the installer." >&2
  exit 1
fi

chmod +x "$TMP_SCRIPT"

echo "Running installer (sudo may prompt for password)..."
sudo bash "$TMP_SCRIPT"

rm -f "$TMP_SCRIPT"
echo "Done."
