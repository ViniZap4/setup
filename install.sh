#!/usr/bin/env bash
set -euo pipefail

# ── Catppuccin Mocha colors ─────────────────────────────────────────────────
MAUVE='\033[38;2;203;166;247m'
GREEN='\033[38;2;166;227;161m'
RED='\033[38;2;243;139;168m'
YELLOW='\033[38;2;249;226;175m'
DIM='\033[38;2;108;112;134m'
RESET='\033[0m'
BOLD='\033[1m'

REPO_URL="https://github.com/ViniZap4/setup.git"
SETUP_DIR="$HOME/setup"
GO_VERSION="1.24.2"
TOTAL_STEPS=5

# ── Helpers ──────────────────────────────────────────────────────────────────
step() {
    printf "\n${MAUVE}${BOLD}[%d/%d]${RESET} %s\n" "$1" "$TOTAL_STEPS" "$2"
}

ok() {
    printf "  ${GREEN}✔${RESET} %s\n" "$1"
}

warn() {
    printf "  ${YELLOW}!${RESET} %s\n" "$1"
}

fail() {
    printf "  ${RED}✖${RESET} %s\n" "$1"
    exit 1
}

dim() {
    printf "  ${DIM}%s${RESET}\n" "$1"
}

# ── Detect OS, architecture, and package manager ────────────────────────────
detect_platform() {
    case "$(uname -s)" in
        Darwin) OS="macos" ;;
        Linux)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                OS="wsl"
            else
                OS="linux"
            fi
            ;;
        *) fail "Unsupported operating system: $(uname -s)" ;;
    esac

    case "$(uname -m)" in
        arm64|aarch64) ARCH="arm64" ;;
        x86_64|amd64)  ARCH="amd64" ;;
        *)             fail "Unsupported architecture: $(uname -m)" ;;
    esac
}

detect_pm() {
    if command -v brew &>/dev/null; then PM="brew"
    elif command -v apt &>/dev/null; then PM="apt"
    elif command -v pacman &>/dev/null; then PM="pacman"
    elif command -v dnf &>/dev/null; then PM="dnf"
    elif command -v zypper &>/dev/null; then PM="zypper"
    elif command -v nix-env &>/dev/null; then PM="nix"
    else PM="unknown"
    fi
}

# ── Step 1: Detect platform ─────────────────────────────────────────────────
step1_platform() {
    step 1 "Detecting platform"
    detect_platform
    detect_pm
    ok "$OS ($ARCH) — $PM"
}

# ── Step 2: Install prerequisites ───────────────────────────────────────────
step2_prerequisites() {
    step 2 "Checking prerequisites"

    local missing=()

    command -v git &>/dev/null || missing+=("git")
    command -v curl &>/dev/null || missing+=("curl")
    command -v make &>/dev/null || missing+=("make")

    if [[ ${#missing[@]} -eq 0 ]]; then
        ok "All prerequisites found (git, curl, make)"
        return
    fi

    dim "Installing: ${missing[*]}"
    case "$PM" in
        brew)   brew install "${missing[@]}" ;;
        apt)    sudo apt-get update -qq && sudo apt-get install -y -qq "${missing[@]}" ;;
        pacman) sudo pacman -S --noconfirm --needed "${missing[@]}" ;;
        dnf)    sudo dnf install -y "${missing[@]}" ;;
        zypper) sudo zypper install -y "${missing[@]}" ;;
        nix)    for pkg in "${missing[@]}"; do nix-env -iA "nixpkgs.$pkg"; done ;;
        *)      fail "Cannot install ${missing[*]}: unknown package manager. Install them manually." ;;
    esac
    ok "Prerequisites installed"
}

# ── Step 3: Install Go ──────────────────────────────────────────────────────
step3_go() {
    step 3 "Ensuring Go $GO_VERSION is installed"

    if command -v go &>/dev/null; then
        CURRENT_GO=$(go version | awk '{print $3}' | sed 's/go//')
        if [ "$CURRENT_GO" = "$GO_VERSION" ]; then
            ok "Go $GO_VERSION already installed"
            return
        fi
        warn "Found Go $CURRENT_GO — need $GO_VERSION"
    fi

    case "$OS" in
        macos)
            if ! command -v brew &>/dev/null; then
                dim "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            dim "Installing Go via Homebrew..."
            brew install go 2>/dev/null || brew upgrade go 2>/dev/null || true
            ;;
        linux|wsl)
            GO_TAR="go${GO_VERSION}.linux-${ARCH}.tar.gz"
            dim "Downloading Go $GO_VERSION for linux/${ARCH}..."
            curl -fsSL "https://go.dev/dl/${GO_TAR}" -o "/tmp/${GO_TAR}"
            dim "Installing to /usr/local/go..."
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf "/tmp/${GO_TAR}"
            rm -f "/tmp/${GO_TAR}"
            export PATH="/usr/local/go/bin:$PATH"
            ;;
    esac

    if command -v go &>/dev/null; then
        ok "Go $(go version | awk '{print $3}' | sed 's/go//') ready"
    else
        fail "Go installation failed"
    fi
}

# ── Step 4: Clone or update repo ────────────────────────────────────────────
step4_repo() {
    step 4 "Setting up repository"

    if [ -d "$SETUP_DIR/.git" ]; then
        dim "Pulling latest changes..."
        git -C "$SETUP_DIR" pull --rebase --recurse-submodules
        git -C "$SETUP_DIR" submodule update --init --recursive
        ok "Updated existing repo"
    else
        dim "Cloning repo..."
        git clone --recursive "$REPO_URL" "$SETUP_DIR"
        ok "Cloned to $SETUP_DIR"
    fi
}

# ── Step 5: Build and install ────────────────────────────────────────────────
step5_build() {
    step 5 "Building setup binary"

    cd "$SETUP_DIR"

    export PATH="$(go env GOPATH)/bin:$PATH"
    go build -o bin/setup ./cmd/setup
    ok "Built bin/setup"

    mkdir -p "$HOME/.local/bin"
    cp bin/setup "$HOME/.local/bin/setup"
    ok "Installed to ~/.local/bin/setup"

    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        warn "Add ~/.local/bin to your PATH"
        dim "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    printf "\n${MAUVE}${BOLD}setup${RESET} ${DIM}— modular dotfiles manager${RESET}\n"

    step1_platform
    step2_prerequisites
    step3_go
    step4_repo
    step5_build

    printf "\n${GREEN}${BOLD}Done!${RESET} Launching setup TUI...\n\n"
    exec "$SETUP_DIR/bin/setup"
}

main "$@"
