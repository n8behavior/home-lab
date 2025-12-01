# home-lab

Scripted, repeatable home lab setup using [Incus](https://linuxcontainers.org/incus/).

## Quick Start

```bash
./bin/init
```

This installs:
- **mdbook** - Documentation system
- **Incus** - Container and VM manager (from [Zabbly](https://github.com/zabbly/incus))
- **Incus Web UI** - Browser-based management

## Prerequisites

- Linux with apt (Debian/Ubuntu)
- Rust toolchain (`cargo`)

## Documentation

Build and serve the docs:

```bash
cd docs && mdbook serve
```

Then open http://localhost:3000