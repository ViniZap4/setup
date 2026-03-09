#!/usr/bin/env bash
set -euo pipefail

# ── Detect OS ──────────────────────────────────────────────────────
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    *) echo "unknown" ;;
  esac
}

detect_pm() {
  if command -v brew &>/dev/null; then echo "brew"
  elif command -v apt &>/dev/null; then echo "apt"
  elif command -v pacman &>/dev/null; then echo "pacman"
  elif command -v dnf &>/dev/null; then echo "dnf"
  elif command -v zypper &>/dev/null; then echo "zypper"
  elif command -v nix-env &>/dev/null; then echo "nix"
  else echo "unknown"
  fi
}

OS=$(detect_os)
PM=$(detect_pm)
echo "→ Detected OS: $OS, Package Manager: $PM"

# ── Install ncdu and vim ──────────────────────────────────────────
install_basics() {
  echo "→ Installing ncdu and vim..."
  case "$PM" in
    brew)   brew install ncdu vim 2>/dev/null || true ;;
    apt)    sudo apt-get update -qq && sudo apt-get install -y ncdu vim 2>/dev/null || true ;;
    pacman) sudo pacman -S --noconfirm --needed ncdu vim 2>/dev/null || true ;;
    dnf)    sudo dnf install -y ncdu vim 2>/dev/null || true ;;
    zypper) sudo zypper install -y ncdu vim 2>/dev/null || true ;;
  esac
}

install_basics

# ── Install Docker ────────────────────────────────────────────────
install_docker() {
  if command -v docker &>/dev/null; then
    echo "→ docker already installed"
    return
  fi

  echo "→ Installing Docker..."
  case "$PM" in
    brew)
      brew install --cask docker 2>/dev/null || true
      echo "→ Open Docker Desktop to finish setup"
      ;;
    apt)
      sudo apt-get update -qq
      sudo apt-get install -y docker.io docker-compose 2>/dev/null || true
      sudo systemctl enable --now docker 2>/dev/null || true
      sudo usermod -aG docker "$USER" 2>/dev/null || true
      echo "→ Log out and back in for docker group to take effect"
      ;;
    pacman)
      sudo pacman -S --noconfirm --needed docker docker-compose 2>/dev/null || true
      sudo systemctl enable --now docker 2>/dev/null || true
      sudo usermod -aG docker "$USER" 2>/dev/null || true
      echo "→ Log out and back in for docker group to take effect"
      ;;
    dnf)
      sudo dnf install -y dnf-plugins-core 2>/dev/null || true
      sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo 2>/dev/null || true
      sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin 2>/dev/null || true
      sudo systemctl enable --now docker 2>/dev/null || true
      sudo usermod -aG docker "$USER" 2>/dev/null || true
      echo "→ Log out and back in for docker group to take effect"
      ;;
    zypper)
      sudo zypper install -y docker docker-compose 2>/dev/null || true
      sudo systemctl enable --now docker 2>/dev/null || true
      sudo usermod -aG docker "$USER" 2>/dev/null || true
      echo "→ Log out and back in for docker group to take effect"
      ;;
  esac
}

install_docker

# ── Install lazydocker ────────────────────────────────────────────
install_lazydocker() {
  if command -v lazydocker &>/dev/null; then
    echo "→ lazydocker already installed"
    return
  fi

  echo "→ Installing lazydocker..."
  case "$PM" in
    brew)
      brew install lazydocker 2>/dev/null || true
      ;;
    pacman)
      sudo pacman -S --noconfirm --needed lazydocker 2>/dev/null || true
      ;;
    *)
      # Binary install from GitHub releases
      LAZYDOCKER_VERSION=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' 2>/dev/null || echo "")
      if [[ -n "$LAZYDOCKER_VERSION" ]]; then
        ARCH="$(uname -m)"
        case "$ARCH" in
          x86_64|amd64) ARCH="x86_64" ;;
          arm64|aarch64) ARCH="arm64" ;;
        esac
        curl -fsSLo /tmp/lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_${ARCH}.tar.gz"
        tar -xzf /tmp/lazydocker.tar.gz -C /tmp lazydocker
        sudo install /tmp/lazydocker /usr/local/bin/lazydocker
        rm -f /tmp/lazydocker /tmp/lazydocker.tar.gz
        echo "✔ lazydocker ${LAZYDOCKER_VERSION} installed"
      else
        echo "→ Could not determine lazydocker version. Install manually:"
        echo "  https://github.com/jesseduffield/lazydocker#installation"
      fi
      ;;
  esac
}

install_lazydocker

echo "✔ Dev tools setup complete"
