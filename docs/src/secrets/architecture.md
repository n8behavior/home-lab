# Secrets Architecture

## Overview

The home lab uses a hybrid secrets model:

```
┌─────────────────────────────────────────────────────────────┐
│                     YubiKey (PIV)                           │
│                   Touch to decrypt                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
┌─────────────────────┐ ┌─────────────────────────────────────┐
│      passage        │ │              SOPS                   │
│   Personal secrets  │ │         Service secrets             │
│                     │ │                                     │
│ • SSH keys          │ │ • Encrypted in git repo             │
│ • GPG keys          │ │ • File-based age key for runtime    │
│ • API tokens        │ │ • (age key stored in passage)       │
│ • atuin key         │ │                                     │
│ • SOPS age key      │ │                                     │
└─────────────────────┘ └─────────────────────────────────────┘
```

## Why This Design?

### Problem: Container Auto-Start

Containers need secrets to start, but YubiKey requires physical touch. After a reboot, you'd need to touch the YubiKey for every container - not practical.

### Solution: Two-Layer Protection

| Layer | Tool | Protection | Use Case |
|-------|------|------------|----------|
| Personal | passage + YubiKey | Touch required | SSH, GPG, API keys |
| Service | SOPS + file key | Automatic | Container configs |

The SOPS file-based key lives inside passage - so editing service secrets still requires YubiKey touch, but runtime decryption is automatic.

## Encryption Stack

```
passage (password-store fork)
    └── age encryption
        └── age-plugin-yubikey
            └── YubiKey PIV applet
```

- **passage**: Simple CLI, stores each secret as encrypted file
- **age**: Modern encryption (replaces GPG in pass)
- **age-plugin-yubikey**: Uses YubiKey's PIV applet for key storage
- **YubiKey PIV**: Hardware-bound private key, touch to use

## File Locations

| Path | Contents | Git? |
|------|----------|------|
| `~/.passage/store/` | Encrypted personal secrets | No |
| `~/.passage/identities` | YubiKey identity reference | No |
| `~/.config/sops/age/keys.txt` | SOPS decryption key | No |
| `secrets/*.yaml` | Encrypted service configs | Yes |
| `/run/secrets/` | Decrypted runtime secrets | No (tmpfs) |

## Security Properties

### What YubiKey Protects

- **Private key extraction**: Impossible - key generated on device
- **Unauthorized use**: Requires physical touch
- **Brute force**: Key never leaves hardware

### What YubiKey Does NOT Protect

- **Decrypted secrets in memory**: Normal for any encryption
- **Secrets after decryption**: Once extracted, same as any file
- **Lost YubiKey**: Backup YubiKey or recovery process needed

## Adding a New Personal Secret

```bash
# Interactive (prompts for value)
passage insert myservice/api-key

# From file
cat secret.txt | passage insert -m myservice/api-key

# Multiline
passage insert -m myservice/config
```

## Adding a New Service Secret

```bash
# Edit encrypted file (touch YubiKey)
sops secrets/myservice.yaml

# Deploy to runtime location
bin/deploy-secrets
```
