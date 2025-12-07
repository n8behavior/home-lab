# Incus

Incus is the container and VM manager for the home lab.

## Projects

Projects are logical namespaces that isolate resources within a single Incus installation. They enable partitioning of instances, images, profiles, storage, and networks.

## Why Projects?

- **Organization**: Group related containers logically
- **Isolation**: Prevent experiments from affecting production services
- **Security**: Apply restrictions at the project level
- **Multi-tenancy**: Different users/projects get their own space

## Our Project Strategy

### `homelab` - Core Infrastructure

The `homelab` project runs critical, always-on services. This project is fully reproducible via IaC definitions in this repository.

Configuration is managed by `make init` (see `create-project` target in Makefile):

```makefile
{{#include ../../Makefile:project-config}}
```

### Default Profile

The default profile for homelab (`incus/profiles/homelab-default.yaml`):

```yaml
{{#include ../../incus/profiles/homelab-default.yaml}}
```

### Experiment Projects

Ad-hoc projects for demos, POCs, and experiments. These can be ephemeral.

## Data Paths

Container data is stored on the host using bind-mounts, following [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html):

```makefile
{{#include ../../Makefile:paths}}
```

## Incus Hosts

The `incus/cloud-init/incus-host.yaml` cloud-init creates containers or VMs capable of running Incus. Use cases include:

- **Clustering**: Build multi-node Incus clusters
- **Nested environments**: Run containers inside containers
- **Development sandboxes**: Isolated Incus instances for experimentation

```bash
incus launch images:ubuntu/24.04/cloud my-incus-host \
  -c cloud-init.user-data="$(cat incus/cloud-init/incus-host.yaml)"

# Wait for cloud-init to complete
incus exec my-incus-host -- cloud-init status --wait

# Verify Incus is installed
incus exec my-incus-host -- incus --version
```

## Testing the Makefile

To validate `make init` in a clean environment:

```bash
# Create a fresh Incus host
incus launch images:ubuntu/24.04/cloud test-host \
  -c cloud-init.user-data="$(cat incus/cloud-init/incus-host.yaml)"
incus exec test-host -- cloud-init status --wait

# Clone and test
incus exec test-host -- bash -c "
  git clone https://github.com/n8behavior/home-lab
  cd home-lab
  make init
  make status
"
```

## Recovery Workflow

After a fresh Ubuntu install from Recovery drive:

```bash
gh repo clone home-lab
cd home-lab
make init
make restore BACKUP_DIR=/media/sandman/Recovery/backups
make status
```

## Troubleshooting

### "Certificate is restricted"

You need admin access to create projects:

```bash
sudo usermod -aG incus-admin $USER
# Logout and login (or reboot if systemd --user is stale)
```

See [The Annals of Incus Hell](./annals.md) for debugging group membership issues.

### "No root device could be found"

The project's default profile is empty. Apply the profiles:

```bash
make setup-profiles
```

### Permission denied on bind-mount

Ensure UID mapping is configured in the profile:

```bash
incus profile show default --project homelab | grep idmap
```
