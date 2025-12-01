# Prerequisites

Before running the init script, ensure you have the following:

## System Requirements

- **Linux** with apt package manager (Debian, Ubuntu, or derivatives)
- **sudo** access for installing system packages

## Rust Toolchain

The Rust toolchain is required to install mdbook via `cargo install`.

### Installing Rust

If you don't have Rust installed, use [rustup](https://rustup.rs/):

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Follow the prompts, then restart your shell or run:

```bash
source "$HOME/.cargo/env"
```

### Verify Installation

```bash
cargo --version
```

## Network Access

The init script needs to download packages from:

- **crates.io** - For mdbook
- **pkgs.zabbly.com** - For Incus packages
