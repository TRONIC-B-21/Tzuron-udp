## Tzuron UDP Server (port 5921)

Installer and pull scripts to deploy the Tzuron UDP server as a systemd service.

### Quick install

- AMD64:
```bash
curl -fsSL https://github.com/TRONIC-B-21/Tzuron-udp/releases/latest/download/Tzuron-linux-amd64 | bash
```

- ARM64:
```bash
curl -fsSL https://github.com/TRONIC-B-21/Tzuron-udp/releases/latest/download/Tzuron-linux-arm64 | bash
```

Optional (non‑interactive passwords):
```bash
export TZURON_PASSWORDS="pass1,pass2"
curl -fsSL https://github.com/TRONIC-B-21/Tzuron-udp/releases/latest/download/Tzuron-linux-amd64 | bash
```

### What the installer does
- Installs binary to `/usr/local/bin/tzuron` from Release asset:
  - AMD64: `https://github.com/TRONIC-B-21/Tzuron-udp/releases/latest/download/tzuron-linux-amd64`
  - ARM64: `https://github.com/TRONIC-B-21/Tzuron-udp/releases/latest/download/tzuron-linux-arm64`
- Creates `/etc/tzuron/config.json` with default:
  - listen `:5921`, obfs `tzuron`, passwords `["tz"]`
- Generates TLS cert/key: `/etc/tzuron/tzuron.crt`, `/etc/tzuron/tzuron.key`
- Installs and starts `tzuron.service`
- Adds iptables DNAT: `UDP 6000–19999 → 5921` and opens UFW for those ports (if UFW exists)

### Service management
```bash
sudo systemctl status tzuron --no-pager
sudo systemctl restart tzuron
sudo journalctl -u tzuron -e --no-pager | tail -n 100
```

### Uninstall
```bash
curl -fsSL https://raw.githubusercontent.com/TRONIC-B-21/Tzuron-udp/main/uninstall_tzuron.sh | sudo bash
```

### Persist NAT rules (optional)
```bash
sudo apt-get install -y iptables-persistent
sudo netfilter-persistent save
```

### Client connection format
Use the server IP and a password (port defaults to 5921):
- IP@PASS
- IP:5921@PASS

Example: `203.0.113.5@mysecret`

### Release assets (expected)
- Pull scripts:
  - `Tzuron-linux-amd64`
  - `Tzuron-linux-arm64`
- Installers:
  - `install_tzuron_amd64.sh`
  - `install_tzuron_arm64.sh`
- Binaries:
  - `tzuron-linux-amd64`
  - `tzuron-linux-arm64`
