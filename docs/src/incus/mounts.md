# Mounting Host Directories

Share host directories with containers using disk devices.

## Basic Mount

```bash
incus config device add <container> <name> disk source=<host-path> path=<container-path>
```

Example:
```bash
incus config device add foo mydata disk source=$HOME/data path=/data
```

## Project Restrictions

The `homelab` project restricts which paths can be mounted. Check allowed paths:

```bash
incus project show homelab | grep disk.paths
```

Default: `$HOME` and `$RECOVERY_DIR` (see Makefile for values)

### Adding Allowed Paths

To mount additional paths, update the project restrictions:

```bash
incus project set homelab restricted.devices.disk.paths="$HOME,$RECOVERY_DIR,/new/path"
```

## Mounting the Recovery Drive

The Recovery USB drive contains backup secrets for testing bootstrap scripts.

**Note:** The container won't start if the Recovery device is configured but the drive isn't attached. Only add the device when testing, then remove it.

```bash
# Mount (drive must be attached)
bin/mount-recovery foo

# Unmount when done
bin/mount-recovery foo remove
```

The Makefile `create-project` target configures the required disk paths automatically.

## UID Matching

Mounted host files are owned by your host UID. For the container user to access them, the container's user must have the same UID.

Check your host UID:
```bash
id -u  # e.g., 1000
```

The default Ubuntu image has a `ubuntu` user with UID 1000, which may conflict. Fix this after creating the container:

```bash
HOST_UID=$(id -u)
incus stop <container>
incus start <container>
incus exec <container> -- bash -c "
  userdel -r ubuntu 2>/dev/null
  usermod -u $HOST_UID $USER
  groupmod -g $HOST_UID $USER
  chown -R $USER:$USER /home/$USER
"
```

Verify:

```bash
incus exec <container> -- id $USER
# Should show uid=<your-uid>($USER) gid=<your-gid>($USER)
```

## Managing Devices

```bash
# List devices on a container
incus config device show foo

# Remove a device
incus config device remove foo recovery
```

## Troubleshooting

### "Disk source path not allowed"

The path isn't in `restricted.devices.disk.paths`. Add it:

```bash
incus project set homelab restricted.devices.disk.paths="$HOME,$RECOVERY_DIR,/new/path"
```

### "Instance not found" with sudo

When using `sudo incus`, it defaults to the `default` project. Specify the project:

```bash
sudo incus --project homelab config device add foo ...
```

Or better: add the path to allowed paths, then use `incus` without sudo.

### Stale Mount After Host Remount

If you unmount and remount a drive on the host while the container is running, the mount inside the container becomes stale:

```
fatal: cannot change to '/media/$USER/Recovery/': Input/output error
```

Fix by removing and re-adding the device:

```bash
incus config device remove foo recovery
incus config device add foo recovery disk source=$RECOVERY_DIR path=$RECOVERY_DIR
```

Or restart the container:

```bash
incus restart foo
```
