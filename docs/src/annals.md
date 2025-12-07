# The Annals of Incus Hell

A collection of debugging adventures, head-scratchers, and hard-won lessons from the trenches of container management. Pour yourself a beverage. You'll need it.

---

## The Case of the Phantom Group Membership

**Date:** December 6, 2025  
**Severity:** Maddening  
**Time to Debug:** ~30 minutes  
**Root Cause:** Zombie `systemd --user`

### The Setup

Adding a user to a Unix group should be simple:

```bash
sudo usermod -aG incus-admin sandman
# logout, login, done... right?
```

Wrong.

### The Symptoms

After adding the user to `incus-admin` and logging out/in:

```bash
$ groups
sandman adm cdrom sudo dip plugdev users lpadmin incus
# Notice anything missing? WHERE IS INCUS-ADMIN?!

$ id sandman
uid=1000(sandman) gid=1000(sandman) groups=...,983(incus-admin)
# But it's RIGHT THERE in /etc/group!

$ incus project show homelab
Error: User does not have permission for project "homelab"
# *flips table*
```

### The Investigation

The `id` command reads from `/etc/group` (the files). The `groups` command shows what the _current process_ actually has. They disagreed.

We traced the process tree:

```
Session leader (PID 133000) → Has incus-admin ✓
Current shell (Claude's bash) → Missing incus-admin ✗
```

Following the breadcrumbs up the process tree:

```bash
$ cat /proc/134869/status | grep PPid  # Claude process
PPid: 134477

$ cat /proc/134477/status | grep PPid  # bash
PPid: 134364

$ cat /proc/134364/status | grep Name  # aha!
Name: tmux: server
```

**TMUX.** The tmux server was the culprit's accomplice. But wait, there's more:

```bash
$ cat /proc/134364/status | grep PPid
PPid: 2804

$ ps -o pid,lstart,cmd -p 2804
  PID                  STARTED CMD
 2804 Thu Dec  4 08:32:42 2025 /usr/lib/systemd/systemd --user
```

### The Revelation

The `systemd --user` process had been running since **December 4th** — two days before we added the group. When we "logged out", the desktop session ended, but `systemd --user` and all its children (including tmux) stayed alive like zombies at a networking event.

When we logged back in, GNOME said "oh, there's already a `systemd --user` running for this UID, I'll just reuse it." And that instance had the _old_ group memberships baked into its process credentials.

The process tree of doom:

```
systemd --user (Dec 4, stale groups)
  └── tmux server (inherited stale groups)
       └── bash (inherited stale groups)
            └── claude (inherited stale groups)
                 └── every command we run (all stale)
```

### Why Didn't Logout Fix It?

On modern Linux desktops with `systemd --user`:

1. **User services persist** across login sessions
2. **Linger** (if enabled) keeps user services running even with no sessions
3. **Any surviving process** in the user slice keeps `systemd --user` alive
4. **tmux** is a classic offender — it's designed to survive logout

Even with `Linger=no`, if anything keeps `systemd --user` alive (like a forgotten tmux session or background service), it won't restart on next login.

### The Fix

**Option 1: The Surgical Strike**

```bash
systemctl --user daemon-reexec  # Restart systemd --user
# Then start a NEW terminal (not from tmux)
```

**Option 2: The Nuclear Option**

```bash
sudo reboot
```

We chose nuclear. Sometimes you just need the catharsis.

### Lessons Learned

1. **`id username` lies to you** — it shows what _should_ be true, not what _is_ true for your process
2. **`groups` (no args) tells the truth** — it shows your current process's actual groups
3. **tmux is immortal** — and it remembers your old group memberships forever
4. **systemd --user is sneaky** — it persists across login sessions
5. **When in doubt, check `/proc/self/status`** — the kernel doesn't lie:

   ```bash
   cat /proc/self/status | grep Groups
   ```

### The Debugging Cheatsheet

When group changes don't take effect:

```bash
# 1. Check what you SHOULD have
id $USER

# 2. Check what you ACTUALLY have
groups  # or: cat /proc/self/status | grep Groups

# 3. If they differ, find the zombie ancestor
pstree -p $$  # trace your ancestry

# 4. Check when systemd --user started
ps -o pid,lstart,cmd -p $(pgrep -u $USER "systemd --user")

# 5. If it's old, you have a zombie problem
# Kill tmux, restart systemd --user, or reboot
```

### Epilogue

The homelab project was eventually created. The containers were deployed. And somewhere, a `systemd --user` process that had been running for two days finally got to rest.

May your groups always be fresh, and your systemd instances short-lived.

---

_"I logged out and logged back in!" — Famous last words_
