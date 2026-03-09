#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Detect package manager ─────────────────────────────────────────
detect_pm() {
  if command -v pacman &>/dev/null; then echo "pacman"
  elif command -v dnf &>/dev/null; then echo "dnf"
  elif command -v apt &>/dev/null; then echo "apt"
  elif command -v zypper &>/dev/null; then echo "zypper"
  elif command -v nix-env &>/dev/null; then echo "nix"
  else echo "unknown"
  fi
}

PM=$(detect_pm)
echo "→ Package Manager: $PM"

# ── Install Hyprland and essentials ──────────────────────────────
install_deps() {
  echo "→ Installing Hyprland and dependencies..."
  case "$PM" in
    pacman)
      sudo pacman -S --noconfirm --needed hyprland kitty wofi waybar hyprpaper 2>/dev/null || true
      ;;
    dnf)
      sudo dnf install -y hyprland kitty wofi waybar 2>/dev/null || true
      ;;
    apt)
      echo "  Hyprland is not in default Ubuntu/Debian repos."
      echo "  Install manually: https://wiki.hyprland.org/Getting-Started/Installation/"
      echo "  Installing available dependencies..."
      sudo apt-get update -qq && sudo apt-get install -y kitty wofi waybar 2>/dev/null || true
      ;;
    zypper)
      sudo zypper install -y hyprland kitty wofi waybar 2>/dev/null || true
      ;;
    nix)
      echo "  Add hyprland to your NixOS/home-manager config"
      echo "  See: https://wiki.hyprland.org/Nix/"
      ;;
    *)
      echo "  Please install Hyprland manually: https://wiki.hyprland.org/Getting-Started/Installation/"
      ;;
  esac
}

install_deps

# ── Create config directory ──────────────────────────────────────
CONFIG_DIR="$HOME/.config/hypr"
mkdir -p "$CONFIG_DIR"

# ── Create symlink ───────────────────────────────────────────────
TARGET="$CONFIG_DIR/hyprland.conf"

if [[ -f "$TARGET" && ! -L "$TARGET" ]]; then
  BACKUP="${TARGET}.backup.$(date +%Y%m%d%H%M%S)"
  echo "→ Backing up existing $TARGET to $BACKUP"
  mv "$TARGET" "$BACKUP"
elif [[ -L "$TARGET" ]]; then
  rm "$TARGET"
fi

ln -s "${SCRIPT_DIR}/hyprland.conf" "$TARGET"
echo "✔ Linked hyprland.conf → $TARGET"
