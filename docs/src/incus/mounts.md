# Mounting Host Directories

Share host directories with containers using disk devices.

## Basic Mount

```bash
incus config device add <container> <name> disk source=<host-path> path=<container-path>
```

Example:
```bash
incus config device add foo mydata disk source=/home/sandman/data path=/data
```

## Project Restrictions

The `user-1000` project restricts which paths can be mounted. Check allowed paths:

```bash
incus project show user-1000 | grep disk.paths
```

Default: `/home/sandman`

### Adding Allowed Paths

To mount paths outside `/home/sandman` (like the Recovery drive), add them to the allowed list:

```bash
sudo incus project set user-1000 restricted.devices.disk.paths="/home/sandman,/media/sandman/Recovery"
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

The `bin/init` script configures the required disk paths automatically.

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
sudo incus project set user-1000 restricted.devices.disk.paths="/home/sandman,/new/path"
```

### "Instance not found" with sudo

When using `sudo incus`, it defaults to the `default` project. Specify the project:

```bash
sudo incus --project user-1000 config device add foo ...
```

Or better: add the path to allowed paths, then use `incus` without sudo.
