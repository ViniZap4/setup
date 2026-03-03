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
TOTAL_STEPS=4

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

# ── Detect OS and architecture ───────────────────────────────────────────────
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

# ── Step 1: Detect platform ─────────────────────────────────────────────────
step1_platform() {
    step 1 "Detecting platform"
    detect_platform
    ok "$OS ($ARCH)"
}

# ── Step 2: Install Go ──────────────────────────────────────────────────────
step2_go() {
    step 2 "Ensuring Go $GO_VERSION is installed"

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
            brew install go@${GO_VERSION%.*} || brew upgrade go@${GO_VERSION%.*} || true
            brew link --overwrite go@${GO_VERSION%.*} 2>/dev/null || true
            ;;
        linux|wsl)
            GO_TAR="go${GO_VERSION}.linux-${ARCH}.tar.gz"
            dim "Downloading Go $GO_VERSION..."
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

# ── Step 3: Clone or update repo ────────────────────────────────────────────
step3_repo() {
    step 3 "Setting up repository"

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

# ── Step 4: Build and install ────────────────────────────────────────────────
step4_build() {
    step 4 "Building setup binary"

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
    step2_go
    step3_repo
    step4_build

    printf "\n${GREEN}${BOLD}Done!${RESET} Launching setup TUI...\n\n"
    exec "$SETUP_DIR/bin/setup"
}

main "$@"
