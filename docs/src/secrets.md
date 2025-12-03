# Secrets Management

This section documents the secrets management strategy for the home lab using [passage](https://github.com/FiloSottile/passage) and YubiKey hardware keys.

## Overview

All secrets are protected by YubiKey - no passwords to remember, just touch the hardware key.

| Secret Type | Tool | Protection |
|-------------|------|------------|
| Personal secrets | passage | YubiKey touch required |
| SSH keys | passage | YubiKey touch required |
| GPG keys | passage | YubiKey touch required |
| Service secrets | SOPS + age | File-based key (stored in passage) |

## Quick Reference

```bash
# View a secret
passage show ssh/id_ed25519

# Add a secret
passage insert -m myservice/api-key

# List all secrets
passage ls

# Backup to USB
rsync -av ~/.passage/store/ /media/sandman/Recovery/secrets/passage-store/
```

## Sections

- [Architecture](./secrets/architecture.md) - How the pieces fit together
- [Passage Setup](./secrets/passage.md) - Setting up passage with YubiKey
- [Backup & Recovery](./secrets/backup.md) - Backup strategy and machine bootstrap
