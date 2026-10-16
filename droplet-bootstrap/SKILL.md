---
name: droplet-bootstrap
version: 1.0.1
description: Bootstrap a fresh DigitalOcean droplet (or any Ubuntu/Debian VM) for demos from the root user's workspace — create the demo user with a home directory, passwordless sudo and SSH access, install the GitHub CLI and Node.js LTS (via mise, plus Go or other tools on request), then install either k3s (only if no Kubernetes is already present) or Docker + Docker Compose, after asking which the user wants. Use when the user wants to set up, provision, prepare or bootstrap a new droplet, VM or demo box, add a demo user, or get k3s, Kubernetes, Docker or Docker Compose onto a server.
user-invocable: true
argument-hint: "[k3s|docker|both|none] [username]"
---

# Droplet bootstrap

Gets a new droplet into a known-good state for demo work. This skill is meant
to be used from **root's workspace on the droplet itself** (Claude Code running
as root). The script at `scripts/bootstrap.sh` (next to this file) does the
work; your job is to pick the options, run it, and confirm the result.

> **For disposable demo VMs only.** The demo user gets passwordless sudo and
> k3s is installed with `curl | sh`. Don't use this to set up a production
> server.

## Step 1: Ask which runtime they want

Unless the user already said, ask with AskUserQuestion. The options are:

| Option | `--runtime` | What gets installed |
|---|---|---|
| Kubernetes (k3s) | `k3s` (default) | k3s, only if no Kubernetes is already on the host |
| Docker + Compose | `docker` | Docker Engine, Docker Compose plugin, buildx |
| Both | `both` | Both of the above |
| Neither | `none` | Only the demo user |

Also confirm the username if they mentioned something other than `demo`, and
whether they want language tools besides Node.js LTS (for example Go). Pass
those as `MISE_TOOLS`.

## Step 2: Run the script as root

```bash
"${SKILL_DIR}/scripts/bootstrap.sh" --user demo --runtime <k3s|docker|both|none>
```

- You're already root, so no `sudo` is needed. If `whoami` is not `root`,
  prefix with `sudo`.
- Use a Bash timeout of at least 300000 ms. Installing k3s or Docker takes
  1–3 minutes.
- Other flags: `--no-ssh-keys` (don't copy root's authorized_keys).
  Env `K3S_VERSION=v1.xx.y+k3s1` pins the k3s version.
  Env `MISE_TOOLS="node@lts go@latest"` picks the tools mise installs
  (default `node@lts`), and `MISE_VERSION` pins the mise release.

## What the script does

1. Creates the demo user with `/home/<user>` and a bash shell. Gives it
   **passwordless sudo** (`sudo` group plus `/etc/sudoers.d/90-<user>`,
   checked with `visudo`). Copies root's `~/.ssh/authorized_keys` so the same
   SSH key works for `ssh demo@<ip>`.
2. Installs the **GitHub CLI** (`gh`) from GitHub's official apt repo every
   time, whatever runtime is chosen. It does not log in. The demo user runs
   `gh auth login` when they need it.
3. Installs **mise** for the demo user (`~/.local/bin/mise`), then runs
   `mise use --global` for `MISE_TOOLS` (default `node@lts`). Tools live in
   the user's home, so `npm i -g` and `go install` work without sudo. Only
   the demo user gets them. Root doesn't. `~/.bashrc` runs `mise activate`
   and `~/.profile` puts the shims on `PATH`. A non-interactive
   `ssh demo@<ip> node` sees neither, so use `~/.local/bin/mise exec -- node`
   there.
4. **docker**: adds Docker's official apt repo, installs `docker-ce` and
   `docker-compose-plugin`, enables the service, and adds the user to the
   `docker` group. If Docker is already installed, it only adds Compose if
   missing.
5. **k3s**: checks for an existing Kubernetes (k3s, rke2, microk8s, k0s,
   kubelet or kubeadm binaries or systemd units, or a cluster `kubectl` can
   reach). Only if none is found does it install k3s. It then waits for the
   node to be `Ready`, copies the kubeconfig to `/home/<user>/.kube/config`,
   exports `KUBECONFIG` in `~/.profile` and `~/.bashrc`, and adds `kubectl`
   completion and a `k` alias. k3s itself is system-wide on purpose (a root
   systemd service, data in `/var/lib/rancher/k3s`). Only the kubeconfig
   belongs to the demo user.

It's safe to run again (it only fills in what's missing), so you can rerun it
with `--runtime docker` later to add Docker to a k3s box. It does **not**
install Pomerium or any demo workloads. Those come later, from the demo
user's home directory.

## Step 3: Verify and report

```bash
su - demo -c 'whoami && sudo -n true && echo sudo-ok && gh --version'
su - demo -c 'mise ls && node --version && npm --version'
su - demo -c 'docker compose version && docker ps'   # docker / both
su - demo -c 'kubectl get nodes'                      # k3s / both
su - demo -c 'bash -ic "type k"'                      # k3s / both: alias present
```

Report the summary block the script printed. If it said "Kubernetes already
present", say what it found and that k3s was not installed. If the user has no
kubeconfig on an existing cluster that isn't k3s, tell them. The script only
sets up k3s's config.

## Troubleshooting

- `k3s node did not become Ready` → `journalctl -u k3s -n 100`. 1 GB droplets
  are tight for k3s, so recommend 2 GB or more.
- `k3s needs systemd` → the host is a container or has no systemd. Use
  `--runtime docker` instead.
- `docker: permission denied` as the demo user → their group membership
  hasn't taken effect yet. Use a fresh login (`su - demo` or a new SSH session).
- `no /root/.ssh/authorized_keys` → the droplet was created without an SSH
  key. Set a password with `passwd demo` or add a key by hand.
- `node: command not found` as the demo user → the shell predates the
  bootstrap. Open a new login shell, or run `eval "$(~/.local/bin/mise activate bash)"`.
- To add a tool later, the demo user runs `mise use -g go@latest`. No root
  needed.
- `kubectl` as the demo user says `permission denied` on
  `/etc/rancher/k3s/k3s.yaml` → `KUBECONFIG` isn't set in that shell. Start
  a new login shell, or `export KUBECONFIG=~/.kube/config`.
- The script opens no firewall ports. Port 6443 (Kubernetes API) stays
  closed, so use `kubectl` on the box or over an SSH tunnel.
