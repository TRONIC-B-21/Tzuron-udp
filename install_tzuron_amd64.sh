#!/bin/bash
# Tzuron UDP Module installer - AMD64

set -euo pipefail

echo "Updating server..."
sudo apt-get update && sudo apt-get upgrade -y

# Stop service if running
systemctl stop tzuron.service 1>/dev/null 2>/dev/null || true

echo "Downloading UDP Service (amd64)"
BINARY_URL="${TZURON_BINARY_URL:-https://github.com/TRONIC-B-21/Tzuron-udp/releases/latest/download/tzuron-linux-amd64}"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$BINARY_URL" -o /usr/local/bin/tzuron
else
  wget -q "$BINARY_URL" -O /usr/local/bin/tzuron
fi
chmod +x /usr/local/bin/tzuron

# Ensure config directory exists
mkdir -p /etc/tzuron

# Create default config if absent
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

echo "Generating cert files..."
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
  -subj "/C=TZ/ST=Dar es Salaam/L=Dar es Salaam/O=Tzuron Corp/OU=VPN/CN=tzuron" \
  -keyout "/etc/tzuron/tzuron.key" -out "/etc/tzuron/tzuron.crt"

# Optimize buffers (like Zivpn does)
sysctl -w net.core.rmem_max=16777216 >/dev/null 2>&1 || true
sysctl -w net.core.wmem_max=16777216 >/dev/null 2>&1 || true

# Create systemd service
cat > /etc/systemd/system/tzuron.service <<'EOF'
[Unit]
Description=Tzuron UDP VPN Server
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

[Install]
WantedBy=multi-user.target
EOF

# Password setup
echo "Tzuron UDP Passwords"
if [ -n "${TZURON_PASSWORDS:-}" ]; then
  input_config="$TZURON_PASSWORDS"
else
  read -r -p "Enter passwords separated by commas (default 'tz'): " input_config
fi

if [ -n "$input_config" ]; then
  IFS=',' read -r -a config <<< "$input_config"
  if [ ${#config[@]} -eq 1 ]; then
    config+=("${config[0]}")
  fi
else
  config=("tz")
fi

new_config_str="\"config\": [$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')]"
sed -i -E "s/\"config\":\\s*\\[[^\\]]*\\]/${new_config_str}/g" /etc/tzuron/config.json

# Enable service
systemctl daemon-reload
systemctl enable tzuron.service
systemctl restart tzuron.service

# Add DNAT rules
IFACE="$(ip -4 route ls | awk '/default/ {print $5; exit}')"
if ! iptables -t nat -C PREROUTING -i "$IFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5921 2>/dev/null; then
  iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5921
fi

# UFW rules (if installed)
if command -v ufw >/dev/null 2>&1; then
  ufw allow 6000:19999/udp || true
  ufw allow 5921/udp || true
fi

echo "✅ Tzuron UDP Installed & Running"
