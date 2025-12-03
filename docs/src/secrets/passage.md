# Passage Setup

[passage](https://github.com/FiloSottile/passage) is a fork of [pass](https://www.passwordstore.org/) that uses [age](https://age-encryption.org/) instead of GPG.

## Prerequisites

- Rust toolchain (for cargo install)
- YubiKey with PIV applet
- pcscd service running

## Installation

The `bootstrap-dotfiles` script handles installation, but here's what it does:

```bash
# Install Rust age implementation and YubiKey plugin
cargo install rage age-plugin-yubikey

# Create symlinks (passage expects 'age' command)
sudo ln -sf ~/.cargo/bin/rage /usr/local/bin/age
sudo ln -sf ~/.cargo/bin/rage-keygen /usr/local/bin/age-keygen

# Install passage
git clone https://github.com/FiloSottile/passage.git /tmp/passage
sudo cp /tmp/passage/src/password-store.sh /usr/local/bin/passage
sudo chmod +x /usr/local/bin/passage
rm -rf /tmp/passage
```

## YubiKey Configuration

### First-Time Setup

```bash
# Interactive setup - creates key on YubiKey
age-plugin-yubikey

# Options used:
# - Name: pangolin-nano (or your preference)
# - PIN policy: Never (touch only, no PIN)
# - Touch policy: Cached (15 second window)
```

### Configure passage to Use YubiKey

```bash
mkdir -p ~/.passage/store

# Add YubiKey identity (for decryption)
age-plugin-yubikey --identity > ~/.passage/identities

# Add YubiKey as recipient (for encryption)
age-plugin-yubikey --list > ~/.passage/store/.age-recipients
```

### Adding a Backup YubiKey

Insert the backup YubiKey and run:

```bash
age-plugin-yubikey  # Configure the new key
age-plugin-yubikey --identity >> ~/.passage/identities
age-plugin-yubikey --list >> ~/.passage/store/.age-recipients
```

Then re-encrypt all secrets to include the new recipient:

```bash
passage init
```

## Usage

### View a Secret

```bash
passage show ssh/id_ed25519
# Touch YubiKey when it blinks
```

### List All Secrets

```bash
passage ls
# or just: passage
```

### Add a Secret

```bash
# Interactive (single line)
passage insert myservice/api-key

# Multiline (Ctrl+D to finish)
passage insert -m myservice/config

# From stdin
cat file.txt | passage insert -m myservice/data
```

### Edit a Secret

```bash
passage edit myservice/api-key
# Opens in $EDITOR, re-encrypts on save
```

### Delete a Secret

```bash
passage rm myservice/api-key
```

### Copy to Clipboard

```bash
passage show -c myservice/api-key
# Copies to clipboard, clears after 45 seconds
```

## Store Structure

```
~/.passage/
├── identities              # YubiKey identity (age1yubikey1...)
└── store/
    ├── .age-recipients     # Public keys for encryption
    ├── ssh/
    │   ├── id_ed25519.age
    │   └── id_rsa.age
    ├── gpg/
    │   ├── secret-keys.age
    │   └── public-keys.age
    └── atuin/
        └── key.age
```

## Troubleshooting

### "age: command not found"

passage expects `age` but we installed `rage`:

```bash
sudo ln -sf ~/.cargo/bin/rage /usr/local/bin/age
```

### YubiKey Not Detected

Ensure pcscd is running:

```bash
sudo systemctl status pcscd
sudo systemctl start pcscd
```

### Touch Not Working

Check YubiKey is recognized:

```bash
age-plugin-yubikey --list
```

### Wrong Identity File

The identity file should contain lines like:

```
#       Serial: 12345678, Slot: 1
#         Name: pangolin-nano
#      Created: Mon, 02 Dec 2024 12:00:00 +0000
#   PIN policy: Never
# Touch policy: Cached
AGE-PLUGIN-YUBIKEY-1ABCDEF...
```

If it's corrupted, regenerate:

```bash
age-plugin-yubikey --identity > ~/.passage/identities
```
