#!/bin/bash
# Tzuron UDP Module installer - ARM64

set -e

echo -e "Updating server"
sudo apt-get update && sudo apt-get upgrade -y

systemctl stop tzuron.service 1> /dev/null 2> /dev/null || true

echo -e "Downloading UDP Service (arm64)"
# Update this URL to your actual arm64 release asset when available
BINARY_URL="${TZURON_BINARY_URL:-https://github.com/TRONIC-B-21/Tzuron-udp/releases/download/TBD/tzuron-linux-arm64}"
wget "$BINARY_URL" -O /usr/local/bin/tzuron 1> /dev/null 2> /dev/null
chmod +x /usr/local/bin/tzuron

mkdir -p /etc/tzuron 1> /dev/null 2> /dev/null

# Create default config if it does not exist
if [ ! -f /etc/tzuron/config.json ]; then
  cat <<'JSON' > /etc/tzuron/config.json
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

echo "Generating cert files:"
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=tzuron" -keyout "/etc/tzuron/tzuron.key" -out "/etc/tzuron/tzuron.crt"

sysctl -w net.core.rmem_max=16777216 1> /dev/null 2> /dev/null
sysctl -w net.core.wmem_max=16777216 1> /dev/null 2> /dev/null

cat <<'EOF' > /etc/systemd/system/tzuron.service
[Unit]
Description=tzuron VPN Server
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

echo -e "TZURON UDP Passwords"
read -p "Enter passwords separated by commas, example: pass1,pass2 (Press enter for Default 'tz'): " input_config

if [ -n "$input_config" ]; then
    IFS=',' read -r -a config <<< "$input_config"
    if [ ${#config[@]} -eq 1 ]; then
        config+=(${config[0]})
    fi
else
    config=("tz")
fi

new_config_str="\"config\": [$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')]"
sed -i -E "s/\"config\": ?\[[[:space:]]*\"tz\"[[:space:]]*\]/${new_config_str}/g" /etc/tzuron/config.json

systemctl daemon-reload
systemctl enable tzuron.service
systemctl start tzuron.service

iptables -t nat -A PREROUTING -i $(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1) -p udp --dport 6000:19999 -j DNAT --to-destination :5921
ufw allow 6000:19999/udp
ufw allow 5921/udp

echo -e "TZURON UDP Installed"


