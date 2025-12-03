# Atuin Server

[Atuin](https://atuin.sh/) syncs shell history across machines. This container runs a self-hosted sync server.

## Container Details

| Property | Value |
|----------|-------|
| Container | `atuin-server` |
| IP Address | 10.206.67.79 |
| Port | 8888 |
| Database | SQLite |

## Installation

The container runs Ubuntu with atuin installed via the official installer:

```bash
# Create the container
incus launch images:ubuntu/24.04 atuin-server

# Install atuin (inside container)
incus exec atuin-server -- bash -c 'curl --proto "=https" --tlsv1.2 -LsSf https://setup.atuin.sh | sh'
```

## Configuration

Config file: `/root/.config/atuin/server.toml`

```toml
host = "0.0.0.0"
port = 8888
open_registration = true
db_uri = "sqlite://.config/atuin-server.db"
```

Key settings:
- `host = "0.0.0.0"` - Listen on all interfaces (required for external access)
- `open_registration = true` - Allow new users to register

## Systemd Service

The server runs as a systemd service at `/etc/systemd/system/atuin-server.service`:

```ini
[Unit]
Description=Atuin Sync Server
After=network.target

[Service]
Type=simple
Environment="HOME=/root"
ExecStart=/root/.atuin/bin/atuin server start
WorkingDirectory=/root
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

**Note:** The `Environment="HOME=/root"` is required - atuin panics without `$HOME` set.

### Service Management

```bash
# Check status
incus exec atuin-server -- systemctl status atuin-server

# View logs
incus exec atuin-server -- journalctl -u atuin-server -f

# Restart
incus exec atuin-server -- systemctl restart atuin-server
```

## Client Configuration

On client machines, configure atuin to use this server:

```bash
# In ~/.config/atuin/config.toml
sync_address = "http://10.206.67.79:8888"
```

Then register and sync:

```bash
atuin register -u <username> -e <email>
atuin sync
```

## Testing

From the host machine:

```bash
curl http://10.206.67.79:8888
```

Should return JSON with server version and a Terry Pratchett quote.
