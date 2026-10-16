#!/usr/bin/env bash
# bootstrap.sh — prepare a fresh DigitalOcean droplet for demos.
#
#   1. Creates a demo user (default: "demo") with a home directory,
#      passwordless sudo, and root's SSH authorized_keys.
#   2. Installs the GitHub CLI (gh), and mise + Node.js LTS (plus any other
#      MISE_TOOLS) for the demo user, regardless of runtime.
#   3. Installs the chosen container runtime:
#        k3s    — k3s, only if no Kubernetes is already present (default)
#        docker — Docker Engine + Docker Compose plugin
#        both   — both of the above
#        none   — neither
#
# Idempotent: safe to re-run. Must run as root (e.g. from root's workspace).
#
# Usage:
#   ./bootstrap.sh [--user NAME] [--runtime k3s|docker|both|none] [--no-ssh-keys]

set -euo pipefail

DEMO_USER="demo"
RUNTIME="k3s"
COPY_SSH_KEYS=1
K3S_VERSION="${K3S_VERSION:-}"   # empty = k3s stable channel
MISE_TOOLS="${MISE_TOOLS:-node@lts}"   # space-separated, e.g. "node@lts go@latest"
MISE_VERSION="${MISE_VERSION:-}"       # empty = installer's latest vetted release

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  echo "Usage: bootstrap.sh [--user NAME] [--runtime k3s|docker|both|none] [--no-ssh-keys]"
  echo "  env K3S_VERSION=v1.xx.y+k3s1 pins the k3s version (default: stable channel)"
  echo "  env MISE_TOOLS=\"node@lts go@latest\" picks the mise tools for the demo user (default: node@lts)"
  echo "  env MISE_VERSION=vYYYY.M.N pins the mise release"
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)        DEMO_USER="${2:?--user needs a value}"; shift 2 ;;
    --user=*)      DEMO_USER="${1#*=}"; shift ;;
    --runtime)     RUNTIME="${2:?--runtime needs a value}"; shift 2 ;;
    --runtime=*)   RUNTIME="${1#*=}"; shift ;;
    --docker)      RUNTIME="docker"; shift ;;
    --no-k3s)      RUNTIME="none"; shift ;;
    --no-ssh-keys) COPY_SSH_KEYS=0; shift ;;
    -h|--help)     usage 0 ;;
    *)             warn "unknown argument: $1"; usage 1 ;;
  esac
done

[[ $EUID -eq 0 ]] || die "must run as root (try: sudo $0)"
[[ "$MISE_TOOLS" =~ ^[A-Za-z0-9@.:/_\ -]+$ ]] || die "invalid MISE_TOOLS: $MISE_TOOLS"
[[ -z "$MISE_VERSION" || "$MISE_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "invalid MISE_VERSION: $MISE_VERSION"
[[ "$DEMO_USER" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || die "invalid username: $DEMO_USER"
case "$RUNTIME" in k3s|docker|both|none) ;; *) die "invalid --runtime: $RUNTIME (k3s|docker|both|none)" ;; esac

WANT_K3S=0; WANT_DOCKER=0
[[ $RUNTIME == k3s    || $RUNTIME == both ]] && WANT_K3S=1
[[ $RUNTIME == docker || $RUNTIME == both ]] && WANT_DOCKER=1

has_systemd() { [[ -d /run/systemd/system ]]; }

apt_install() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq "$@" >/dev/null
}

# --------------------------------------------------------------------------
# 1. Demo user + home directory + sudo
# --------------------------------------------------------------------------
if id "$DEMO_USER" &>/dev/null; then
  log "user '$DEMO_USER' already exists"
else
  log "creating user '$DEMO_USER'"
  useradd --create-home --shell /bin/bash "$DEMO_USER"
fi

DEMO_HOME="$(getent passwd "$DEMO_USER" | cut -d: -f6)"
DEMO_GROUP="$(id -gn "$DEMO_USER")"

if [[ ! -d "$DEMO_HOME" ]]; then
  log "creating home directory $DEMO_HOME"
  mkdir -p "$DEMO_HOME"
  cp -rT /etc/skel "$DEMO_HOME"
fi
chown "$DEMO_USER:$DEMO_GROUP" "$DEMO_HOME"
chmod 750 "$DEMO_HOME"

command -v visudo &>/dev/null || { log "installing sudo"; apt_install sudo; }
log "granting passwordless sudo to '$DEMO_USER'"
usermod -aG sudo "$DEMO_USER" 2>/dev/null || usermod -aG wheel "$DEMO_USER" 2>/dev/null || true
sudoers="/etc/sudoers.d/90-${DEMO_USER}"
echo "$DEMO_USER ALL=(ALL) NOPASSWD:ALL" > "$sudoers.tmp"
chmod 440 "$sudoers.tmp"
if visudo -cf "$sudoers.tmp" >/dev/null; then
  mv "$sudoers.tmp" "$sudoers"
else
  rm -f "$sudoers.tmp"; die "generated sudoers file failed validation"
fi

if [[ $COPY_SSH_KEYS -eq 1 ]]; then
  if [[ -s /root/.ssh/authorized_keys ]]; then
    log "copying root's SSH authorized_keys to '$DEMO_USER'"
    install -d -m 700 -o "$DEMO_USER" -g "$DEMO_GROUP" "$DEMO_HOME/.ssh"
    touch "$DEMO_HOME/.ssh/authorized_keys"
    # Append only keys not already present.
    while IFS= read -r key; do
      [[ -z "$key" || "$key" == \#* ]] && continue
      grep -qxF "$key" "$DEMO_HOME/.ssh/authorized_keys" || echo "$key" >> "$DEMO_HOME/.ssh/authorized_keys"
    done < /root/.ssh/authorized_keys
    chown "$DEMO_USER:$DEMO_GROUP" "$DEMO_HOME/.ssh/authorized_keys"
    chmod 600 "$DEMO_HOME/.ssh/authorized_keys"
  else
    warn "no /root/.ssh/authorized_keys found; skipping SSH key copy"
  fi
fi

# --------------------------------------------------------------------------
# 2. GitHub CLI (always)
# --------------------------------------------------------------------------
if command -v gh &>/dev/null; then
  log "GitHub CLI already installed ($(gh --version | head -1))"
else
  log "adding GitHub CLI apt repository"
  apt_install ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
  chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list
  log "installing GitHub CLI"
  apt_install gh
fi

# --------------------------------------------------------------------------
# 2b. mise + Node.js (always), installed for the demo user, not system-wide.
#     Tools live in the user's home, so `npm i -g` / `go install` need no sudo.
# --------------------------------------------------------------------------
as_demo() { su - "$DEMO_USER" -c "$1"; }
MISE_BIN="$DEMO_HOME/.local/bin/mise"

if [[ -x "$MISE_BIN" ]]; then
  log "mise already installed for '$DEMO_USER' ($(as_demo "$MISE_BIN --version" 2>/dev/null))"
else
  command -v curl &>/dev/null || { log "installing curl"; apt_install curl; }
  log "installing mise${MISE_VERSION:+ $MISE_VERSION} for '$DEMO_USER'"
  as_demo "curl -fsSL https://mise.run | MISE_QUIET=1 MISE_VERSION='$MISE_VERSION' sh" >/dev/null
fi

# Interactive shells get `mise activate`; login shells also get the shims on PATH.
if ! grep -q '# droplet-bootstrap: mise' "$DEMO_HOME/.bashrc" 2>/dev/null; then
  printf '\n# droplet-bootstrap: mise\neval "$(~/.local/bin/mise activate bash)"\n' >> "$DEMO_HOME/.bashrc"
  chown "$DEMO_USER:$DEMO_GROUP" "$DEMO_HOME/.bashrc"
fi
if ! grep -q '# droplet-bootstrap: mise' "$DEMO_HOME/.profile" 2>/dev/null; then
  printf '\n# droplet-bootstrap: mise\nexport PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"\n' >> "$DEMO_HOME/.profile"
  chown "$DEMO_USER:$DEMO_GROUP" "$DEMO_HOME/.profile"
fi

log "installing with mise: $MISE_TOOLS"
as_demo "$MISE_BIN use --global --yes $MISE_TOOLS" >/dev/null

# --------------------------------------------------------------------------
# 3a. Docker Engine + Compose plugin
# --------------------------------------------------------------------------
install_docker() {
  # Docker's official apt repository (Ubuntu/Debian).
  . /etc/os-release
  local distro="$ID"
  [[ "$distro" == ubuntu || "$distro" == debian ]] || distro="${ID_LIKE%% *}"
  [[ "$distro" == ubuntu || "$distro" == debian ]] || die "Docker install supports Ubuntu/Debian only (found: $ID)"

  log "adding Docker apt repository ($distro $VERSION_CODENAME)"
  apt_install ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/$distro/gpg" -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$distro $VERSION_CODENAME stable" \
    > /etc/apt/sources.list.d/docker.list

  log "installing Docker Engine + Compose plugin"
  apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

if [[ $WANT_DOCKER -eq 1 ]]; then
  if command -v docker &>/dev/null; then
    log "Docker already installed ($(docker --version 2>/dev/null))"
    if ! docker compose version &>/dev/null; then
      log "installing Docker Compose plugin"
      apt_install docker-compose-plugin 2>/dev/null || apt_install docker-compose-v2 \
        || warn "could not install Docker Compose plugin"
    fi
  else
    install_docker
  fi

  if has_systemd; then
    systemctl enable --now docker >/dev/null 2>&1 || warn "could not start docker service"
  fi

  getent group docker &>/dev/null || groupadd docker
  log "adding '$DEMO_USER' to the docker group"
  usermod -aG docker "$DEMO_USER"
fi

# --------------------------------------------------------------------------
# 3b. Kubernetes (k3s) — only if nothing is already present
# --------------------------------------------------------------------------
detect_kubernetes() {
  # Prints a short description of an existing Kubernetes install and returns 0,
  # or returns 1 if none is found. A bare kubectl client does not count.
  local b svc
  for b in k3s rke2 microk8s k0s kubelet kubeadm; do
    if command -v "$b" &>/dev/null; then echo "$b binary at $(command -v "$b")"; return 0; fi
  done
  for svc in k3s k3s-agent rke2-server rke2-agent k0scontroller k0sworker kubelet snap.microk8s.daemon-kubelite; do
    if systemctl list-unit-files "${svc}.service" 2>/dev/null | grep -q "^${svc}\.service"; then
      echo "systemd unit ${svc}.service"; return 0
    fi
  done
  if command -v kubectl &>/dev/null \
     && kubectl --request-timeout=5s get --raw /readyz &>/dev/null; then
    echo "reachable cluster via kubectl ($(kubectl config current-context 2>/dev/null || echo default))"
    return 0
  fi
  return 1
}

install_user_kubeconfig() {
  # Copy k3s's admin kubeconfig into the demo user's ~/.kube/config.
  local src=/etc/rancher/k3s/k3s.yaml
  [[ -f "$src" ]] || return 0
  log "writing $DEMO_HOME/.kube/config"
  install -d -m 700 -o "$DEMO_USER" -g "$DEMO_GROUP" "$DEMO_HOME/.kube"
  install -m 600 -o "$DEMO_USER" -g "$DEMO_GROUP" "$src" "$DEMO_HOME/.kube/config"
}

if [[ $WANT_K3S -eq 1 ]]; then
  if existing="$(detect_kubernetes)"; then
    log "Kubernetes already present ($existing); not installing k3s"
    # If it's k3s, still make sure the demo user can use it.
    [[ -f "$DEMO_HOME/.kube/config" ]] || install_user_kubeconfig
  else
    has_systemd || die "k3s needs systemd; this host has none"
    command -v curl &>/dev/null || { log "installing curl"; apt_install curl; }
    log "installing k3s${K3S_VERSION:+ $K3S_VERSION}"
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" sh -s - server

    log "waiting for node to become Ready"
    for _ in $(seq 1 60); do
      if k3s kubectl get nodes 2>/dev/null | grep -q ' Ready'; then break; fi
      sleep 2
    done
    k3s kubectl get nodes 2>/dev/null | grep -q ' Ready' || die "k3s node did not become Ready within 120s (check: journalctl -u k3s)"

    install_user_kubeconfig
  fi

  # Shell conveniences for kubectl.
  if command -v kubectl &>/dev/null && ! grep -q '# droplet-bootstrap' "$DEMO_HOME/.bashrc" 2>/dev/null; then
    log "adding kubectl alias + completion to $DEMO_HOME/.bashrc"
    cat >> "$DEMO_HOME/.bashrc" <<'EOF'

# droplet-bootstrap
if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion bash)
  alias k=kubectl
  complete -o default -F __start_kubectl k
fi
EOF
    chown "$DEMO_USER:$DEMO_GROUP" "$DEMO_HOME/.bashrc"
  fi
fi

# --------------------------------------------------------------------------
log "done"
cat <<EOF

  user:       $DEMO_USER  (passwordless sudo)
  home:       $DEMO_HOME
  gh:         $(gh --version 2>/dev/null | head -1 || echo "not installed")
  node:       $(as_demo "$MISE_BIN exec -- node --version" 2>/dev/null || echo "not installed")  (via mise, demo user only)
  mise tools: $MISE_TOOLS
  runtime:    $RUNTIME
  docker:     $(command -v docker &>/dev/null && docker --version 2>/dev/null || echo "not installed")
  compose:    $(docker compose version 2>/dev/null || echo "not installed")
  kubeconfig: $([[ -f "$DEMO_HOME/.kube/config" ]] && echo "$DEMO_HOME/.kube/config" || echo "none")

  Next: su - $DEMO_USER   (or: ssh $DEMO_USER@<droplet-ip>)
EOF
