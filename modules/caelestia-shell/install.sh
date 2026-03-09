#!/usr/bin/env bash
set -euo pipefail

# ── Detect package manager ─────────────────────────────────────────
detect_pm() {
  if command -v pacman &>/dev/null; then echo "pacman"
  elif command -v nix-env &>/dev/null; then echo "nix"
  elif command -v dnf &>/dev/null; then echo "dnf"
  elif command -v apt &>/dev/null; then echo "apt"
  elif command -v zypper &>/dev/null; then echo "zypper"
  else echo "unknown"
  fi
}

PM=$(detect_pm)
echo "→ Package Manager: $PM"

# ── Architecture check ───────────────────────────────────────────
ARCH="$(uname -m)"
if [[ "$ARCH" != "x86_64" && "$ARCH" != "amd64" ]]; then
  echo "✖ Caelestia Shell requires x86_64 (amd64) architecture"
  echo "  Detected: $ARCH"
  exit 1
fi

# ── Install caelestia-shell ──────────────────────────────────────
echo "→ Setting up Caelestia Shell..."
case "$PM" in
  pacman)
    if command -v yay &>/dev/null; then
      yay -S --noconfirm caelestia-shell 2>/dev/null || true
    elif command -v paru &>/dev/null; then
      paru -S --noconfirm caelestia-shell 2>/dev/null || true
    else
      echo "  AUR helper (yay/paru) not found."
      echo "  Install one, then run: yay -S caelestia-shell"
    fi
    ;;
  nix)
    echo "  Add to your flake or run:"
    echo "    nix run github:caelestia-dots/shell"
    ;;
  *)
    INSTALL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia"
    if [[ ! -d "$INSTALL_DIR" ]]; then
      echo "  Cloning caelestia-shell..."
      git clone https://github.com/caelestia-dots/shell.git "$INSTALL_DIR"
    else
      echo "  Updating existing installation..."
      git -C "$INSTALL_DIR" pull
    fi

    # Install build deps if possible
    case "$PM" in
      apt)
        echo "  Installing build dependencies..."
        sudo apt-get update -qq
        sudo apt-get install -y cmake ninja-build 2>/dev/null || true
        ;;
      dnf)
        sudo dnf install -y cmake ninja-build 2>/dev/null || true
        ;;
      zypper)
        sudo zypper install -y cmake ninja 2>/dev/null || true
        ;;
    esac

    echo "  Build with:"
    echo "    cd $INSTALL_DIR && cmake -B build -GNinja && ninja -C build"
    ;;
esac

echo ""
echo "→ Requires Hyprland compositor"
echo "→ Config: ~/.config/caelestia/shell.json"
echo "→ See: https://github.com/caelestia-dots/shell"
echo "✔ Caelestia Shell setup complete"
