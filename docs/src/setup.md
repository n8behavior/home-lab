# Setup

This section covers everything needed to set up the home lab environment.

## Overview

The setup process is handled by the `bin/init` script, which installs:

1. **mdbook** - For building this documentation
2. **Incus** - Container and VM management from the [Zabbly repository](https://github.com/zabbly/incus)
3. **Incus Web UI** - Browser-based management interface

## Quick Start

```bash
./bin/init
```

The script is idempotent - safe to run multiple times.

## Sections

- [Prerequisites](./setup/prerequisites.md) - What you need before running the init script
- [Installation](./setup/installation.md) - Details on what the init script does
