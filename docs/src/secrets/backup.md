# Backup & Recovery

## Backup Strategy

All secrets are backed up to an encrypted USB drive (Recovery drive). The passage store is already encrypted with age, so the backup is a simple file copy.

```
/media/sandman/Recovery/
├── dotfiles/                    # Clone of dotfiles repo
└── secrets/
    └── passage-store/           # Encrypted passage store backup
```

## Backup Commands

### Quick Backup

```bash
# Push local changes to Recovery drive
bin/passage-backup push

# Pull from Recovery drive (restore)
bin/passage-backup pull
```

### Manual Backup

```bash
rsync -av --delete ~/.passage/store/ /media/sandman/Recovery/secrets/passage-store/
```

## What's Backed Up

| Secret | Location in passage | Notes |
|--------|---------------------|-------|
| SSH keys | `ssh/id_ed25519`, `ssh/id_rsa` | Private and public |
| GPG keys | `gpg/secret-keys`, `gpg/public-keys` | Exported armor format |
| GPG trust | `gpg/ownertrust` | Trust database |
| SOPS key | `sops/age-key` | File-based age key |
| Atuin key | `atuin/key` | Sync encryption key |
| Keyrings | `keyrings/login.keyring` | GNOME keyring |

## New Machine Bootstrap

### Prerequisites

1. Recovery USB drive mounted at `/media/sandman/Recovery`
2. YubiKey available

### Steps

```bash
# 1. Get the bootstrap script
curl -O https://raw.githubusercontent.com/n8behavior/dotfiles/main/.local/bin/bootstrap-dotfiles
chmod +x bootstrap-dotfiles

# 2. Run it (installs everything, restores secrets)
./bootstrap-dotfiles
```

The script will:
1. Install system packages (pcscd, build tools)
2. Install Rust and cargo
3. Install rage, age-plugin-yubikey, passage
4. Restore passage store from Recovery drive
5. Setup YubiKey identity (requires YubiKey)
6. Extract SSH keys (touch YubiKey)
7. Import GPG keys (touch YubiKey)
8. Restore SOPS key, atuin key, keyrings

### Manual Recovery

If the bootstrap script isn't available:

```bash
# Install dependencies
sudo apt install pcscd libpcsclite-dev pkgconf
cargo install rage age-plugin-yubikey

# Create symlinks
sudo ln -sf ~/.cargo/bin/rage /usr/local/bin/age
sudo ln -sf ~/.cargo/bin/rage-keygen /usr/local/bin/age-keygen

# Install passage
git clone https://github.com/FiloSottile/passage.git /tmp/passage
sudo cp /tmp/passage/src/password-store.sh /usr/local/bin/passage
sudo chmod +x /usr/local/bin/passage

# Restore passage store
mkdir -p ~/.passage
cp -r /media/sandman/Recovery/secrets/passage-store ~/.passage/store
chmod 700 ~/.passage/store

# Setup YubiKey identity
age-plugin-yubikey --identity > ~/.passage/identities

# Now you can access secrets
passage show ssh/id_ed25519
```

## Disaster Recovery

### Lost Primary YubiKey

If you have a backup YubiKey configured:

1. Insert backup YubiKey
2. Secrets are already encrypted to both keys
3. Update `~/.passage/identities` to use backup key
4. Order replacement primary key
5. When received, add as new recipient

### Lost All YubiKeys

**This is catastrophic** - without a YubiKey, you cannot decrypt secrets.

Mitigations:
- Always configure a backup YubiKey
- Consider storing a paper backup of critical secrets in a safe
- The Recovery USB drive is useless without a YubiKey

### Corrupted Recovery Drive

Restore from primary machine:

```bash
bin/passage-backup push
```

Or manually:

```bash
rsync -av ~/.passage/store/ /media/sandman/Recovery/secrets/passage-store/
```

## Backup Verification

Periodically verify backups are working:

```bash
# 1. Check Recovery drive is accessible
ls /media/sandman/Recovery/secrets/passage-store/

# 2. Compare file counts
find ~/.passage/store -name "*.age" | wc -l
find /media/sandman/Recovery/secrets/passage-store -name "*.age" | wc -l

# 3. Test restore on a different machine (optional)
```

## Security Notes

- The Recovery drive contains encrypted files only
- Without a registered YubiKey, the backup is useless
- Store the Recovery drive securely (not with your YubiKey)
- Consider encrypting the USB drive itself (LUKS) for defense in depth
