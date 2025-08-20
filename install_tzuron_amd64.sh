#!/bin/bash
# Tzuron UDP Module installer - AMD64
set -euo pipefail

echo "[*] Updating server packages..."
sudo apt-get update && sudo apt-get upgrade -y

systemctl stop tzuron.service 1>/dev/null 2>&1 || true

echo "[*] Downloading Tzuron UDP binary (amd64)..."
BINARY_URL="${TZURON_BINARY_URL:-https://github.com/TRONIC-B-21/Tzuron-udp/releases/latest/download/tzuron-linux-amd64}"
if command -v curl >/dev/null 2>&1; then
  curl -fL "$BINARY_URL" -o /usr/local/bin/tzuron
else
  wget -q "$BINARY_URL" -O /usr/local/bin/tzuron
fi
chmod +x /usr/local/bin/tzuron

if [ ! -s /usr/local/bin/tzuron ]; then
  echo "❌ Failed to download tzuron binary"
  exit 1
fi

echo "[*] Preparing config..."
mkdir -p /etc/tzuron

if [ ! -f /etc/tzuron/config.json ]; then
  cat > /etc/tzuron/config.json <<'JSON'
{
  "listen": ":5921",
  "cert": "/etc/tzuron/tzuron.crt",
  "key": "/etc/tzuron/tzuron.key",
  "obfs": "tzuron",
  "auth": {
    "mode": "passwords",
    "config": ["tz"]
  }
}
JSON
fi

if [ ! -f /etc/tzuron/tzuron.key ] || [ ! -f /etc/tzuron/tzuron.crt ]; then
  echo "[*] Generating cert files..."
  openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=tzuron" \
    -keyout "/etc/tzuron/tzuron.key" -out "/etc/tzuron/tzuron.crt"
fi

read -r -p "Enter passwords (comma separated, default: tz): " input_config
if [ -z "$input_config" ]; then input_config="tz"; fi

IFS=',' read -r -a config <<< "$input_config"
jq --argjson cfg "$(printf '%s\n' "${config[@]}" | jq -R . | jq -s .)" \
   '.auth.config = $cfg' /etc/tzuron/config.json > /etc/tzuron/config.tmp \
   && mv /etc/tzuron/config.tmp /etc/tzuron/config.json

cat > /etc/systemd/system/tzuron.service <<'EOF'
[Unit]
Description=Tzuron VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/tzuron
ExecStart=/usr/local/bin/tzuron server -c /etc/tzuron/config.json
Restart=always
RestartSec=3
Environment=TZURON_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true
LimitNOFILE=1048576
LimitNPROC=512

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tzuron.service
systemctl restart tzuron.service

if command -v ufw >/dev/null 2>&1; then
  ufw allow 5921/udp || true
fi

echo "✅ Tzuron UDP installed and running on port 5921"
