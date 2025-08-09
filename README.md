## Tzuron UDP (Server)

Minimal UDP tunnel server with systemd management on port 5921. Provides amd64 and arm64 installers and pull scripts.

### Quick install

- AMD64:
```bash
curl -fsSL https://github.com/TRONIC-B-21/Tzuron-udp/releases/latest/download/Tzuron-linux-amd64 | bash
```

- ARM64:
```bash
curl -fsSL https://github.com/TRONIC-B-21/Tzuron-udp/releases/latest/download/Tzuron-linux-arm64 | bash
```

The installer will:
- Update apt and install the server binary to `/usr/local/bin/tzuron`
- Create config at `/etc/tzuron/config.json`
- Generate TLS cert/key at `/etc/tzuron/tzuron.crt` and `/etc/tzuron/tzuron.key`
- Install and start `systemd` unit `tzuron.service`
- Add iptables DNAT: UDP 6000–19999 → 5921 and open UFW for those ports

### Configuration

- Default config path: `/etc/tzuron/config.json`
- Default listen port: `:5921`
- Default obfuscation tag: `tzuron`
- Default passwords list: `["tz"]`

Example:
```json
{
  "listen": ":5921",
  "cert": "/etc/tzuron/tzuron.crt",
  "key": "/etc/tzuron/tzuron.key",
  "obfs": "tzuron",
  "auth": { "mode": "passwords", "config": ["tz"] }
}
```

The installer prompts for a comma‑separated password list and updates `config.json`. To change later, edit the file and restart the service.

### Service management

```bash
sudo systemctl status tzuron --no-pager
sudo systemctl restart tzuron
sudo systemctl stop tzuron
sudo journalctl -u tzuron -e --no-pager | tail -n 100
```

### Firewall and NAT

- DNAT rule: `6000:19999/udp → 5921` via iptables `PREROUTING`
- UFW rules opened for `6000:19999/udp` and `5921/udp`

To persist iptables rules across reboots:
```bash
sudo apt-get install -y iptables-persistent
sudo netfilter-persistent save
```

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/TRONIC-B-21/Tzuron-udp/main/uninstall_tzuron.sh | sudo bash
```

Removes the service, binary, and `/etc/tzuron` directory. You may also remove firewall/NAT rules manually if desired.

### Releases and assets

- Pull scripts (published as release assets): `Tzuron-linux-amd64`, `Tzuron-linux-arm64`
- Installers (referenced by pull scripts): `install_tzuron_amd64.sh`, `install_tzuron_arm64.sh`
- Server binary (installed to `/usr/local/bin/tzuron`)

### Requirements

- Ubuntu/Debian with `curl` or `wget`, `systemd`, and sudo privileges.


