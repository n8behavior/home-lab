# Incus

Incus is the container and VM manager for the home lab.

## User Project

Containers run in the `user-1000` project, which provides isolation and restrictions for non-root usage.

```bash
# List containers (uses current project)
incus list

# Check current project
incus project list
```

## Sections

- [Mounting Host Directories](./incus/mounts.md) - Share files between host and containers
