# Installation

The `bin/init` script handles all installation. This page documents what it does.

## Running the Script

```bash
./bin/init
```

The script will prompt for sudo password when needed.

## What Gets Installed

### mdbook

Installed via `cargo install mdbook`. Used to build this documentation.

```bash
# Build the docs
cd docs && mdbook build

# Serve locally with live reload
cd docs && mdbook serve
```

### Incus

Installed from the [Zabbly stable repository](https://github.com/zabbly/incus):

1. Adds the Zabbly GPG key to `/etc/apt/keyrings/zabbly.asc`
2. Adds the apt source to `/etc/apt/sources.list.d/zabbly-incus-stable.sources`
3. Installs `incus` and `incus-ui-canonical` packages

### Incus Web UI

The web interface is installed as part of the `incus-ui-canonical` package.

Access it at: **https://localhost:8443**

Note: Uses a self-signed certificate, so you'll need to accept the browser warning.

The init script automatically enables the web UI by setting `core.https_address`.

## Local Unix Sockets and User Groups

Incus provides two local unix sockets with different access levels:

| Socket | Group | Access Level |
|--------|-------|--------------|
| `/var/lib/incus/unix.socket` | `incus-admin` | Full admin access |
| `/var/lib/incus/unix.socket.user` | `incus` | Limited user access |

### incus-admin group

Members have full access to:
- Storage pool management
- Network configuration
- Server settings
- All container/VM operations

```bash
sudo usermod -aG incus-admin $USER
```

### incus group

Members have limited access to:
- Launch containers in their own user namespace
- Manage their own instances

```bash
sudo usermod -aG incus $USER
```

**Note:** Log out and back in after adding yourself to groups.

## Post-Installation

Incus is ready to use immediately after installation - no `incus admin init` required. The installer creates a default storage pool using the `dir` backend.

For more advanced configuration (ZFS/Btrfs storage, custom networks, clustering), you can use:

```bash
incus admin init --preseed < config.yaml
```

## Idempotency

The script is safe to run multiple times:

- Checks if mdbook is already installed before running `cargo install`
- Checks if Incus is already installed before adding repositories
- Checks if web UI is already enabled before configuring `core.https_address`
