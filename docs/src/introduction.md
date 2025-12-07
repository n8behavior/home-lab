# Introduction

Scripted, repeatable home lab setup using [Incus](https://linuxcontainers.org/incus/) for container and VM management.

## Quick Start

```bash
gh repo clone home-lab
cd home-lab
make init
```

Requires Linux with apt (Debian/Ubuntu) and sudo access.

## What `make init` Does

1. Installs Incus from [Zabbly repository](https://github.com/zabbly/incus)
2. Enables web UI at https://localhost:8443
3. Creates `homelab` project with UID mapping and device restrictions
4. Applies default profile with network and storage

## Other Commands

```bash
make status   # Show projects and instances
make backup   # Backup data to Recovery drive
make restore  # Restore from Recovery drive
make help     # Show all targets
```

## User Groups

After installation, add yourself to the appropriate group:

| Group | Access | Command |
|-------|--------|---------|
| `incus-admin` | Full admin access | `sudo usermod -aG incus-admin $USER` |
| `incus` | Limited user access | `sudo usermod -aG incus $USER` |

**Important:** Log out and back in after adding groups. If groups still don't apply, see [The Annals of Incus Hell](./annals.md) for debugging.
