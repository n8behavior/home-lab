# home-lab

Scripted, repeatable home lab setup using [Incus](https://linuxcontainers.org/incus/).

## Quick Start

```bash
make init
```

This bootstraps:
- **Incus** - Container and VM manager (from [Zabbly](https://github.com/zabbly/incus))
- **Incus Web UI** - Browser-based management at https://localhost:8443
- **homelab project** - Isolated project with UID mapping and device restrictions

## Prerequisites

- Linux with apt (Debian/Ubuntu)

## Other Commands

```bash
make status   # Show projects and instances
make backup   # Backup data to Recovery drive
make restore  # Restore from Recovery drive
make help     # Show all targets
```

## Documentation

Docs are built with [mdbook](https://rust-lang.github.io/mdBook/):

```bash
make docs-serve
```

Then open http://localhost:3000
