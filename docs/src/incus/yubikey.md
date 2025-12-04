# YubiKey Passthrough

Pass a YubiKey into a container for use with passage, age-plugin-yubikey, and other PIV/smart card applications.

## Prerequisites

- YubiKey plugged into the host
- Container with pcscd installed
- User in the `plugdev` group

## Quick Setup

For a new container, run these steps:

```bash
# 1. Add YubiKey device to container
incus config device add <container> yubikey usb vendorid=1050

# 2. Add user to plugdev group
incus exec <container> -- usermod -aG plugdev sandman

# 3. Create polkit rule for smart card access
incus exec <container> -- bash -c 'cat > /etc/polkit-1/rules.d/01-pcscd.rules << "EOF"
polkit.addRule(function(action, subject) {
    if ((action.id == "org.debian.pcsc-lite.access_pcsc" ||
         action.id == "org.debian.pcsc-lite.access_card") &&
        subject.isInGroup("plugdev")) {
        return polkit.Result.YES;
    }
});
EOF'

# 4. Restart services
incus exec <container> -- systemctl restart polkit pcscd
```

## Project Configuration

The `user-1000` project must allow USB devices. This is configured by `bin/init`:

```bash
sudo incus project set user-1000 restricted.devices.usb=allow
```

## User UID Matching

For mounted host directories (like Recovery drive) to be accessible, the container user must have UID 1000 to match the host user.

The default Ubuntu image has a `ubuntu` user with UID 1000. To fix this:

```bash
# Stop container to avoid processes holding the user
incus stop <container>
incus start <container>

# Remove ubuntu user and change sandman to UID 1000
incus exec <container> -- bash -c '
  userdel -r ubuntu 2>/dev/null
  usermod -u 1000 sandman
  groupmod -g 1000 sandman
  chown -R sandman:sandman /home/sandman
'
```

## Verification

Test that the YubiKey is accessible:

```bash
incus exec <container> -- su -l sandman -c 'age-plugin-yubikey --list'
```

Should display your YubiKey identity:

```
#       Serial: 12345678, Slot: 1
#         Name: pangolin-nano
#   PIN policy: Never
# Touch policy: Cached
age1yubikey1q...
```

## Troubleshooting

### "USB devices are forbidden"

The project doesn't allow USB devices:

```bash
sudo incus project set user-1000 restricted.devices.usb=allow
```

### "Access was denied because of a security violation"

The polkit rule is missing or the user isn't in `plugdev`. Check:

```bash
# Verify group membership
incus exec <container> -- su -l sandman -c 'id'

# Check polkit rule exists
incus exec <container> -- cat /etc/polkit-1/rules.d/01-pcscd.rules

# Check pcscd logs
incus exec <container> -- journalctl -u pcscd -n 20
```

### YubiKey not detected

Verify the device is passed through:

```bash
incus config device show <container>
```

Check if pcscd is running:

```bash
incus exec <container> -- systemctl status pcscd
```

### Touch not working through remote shell

YubiKey touch prompts don't work through `incus exec` or SSH. You need to either:

- Run commands in an interactive terminal inside the container
- Use a VNC/desktop session
- Pre-authorize with touch before running batch commands (touch policy "Cached" gives 15 seconds)
