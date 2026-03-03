# setup

Modular dotfiles manager — each config lives in its own repo as a git submodule, managed by a Go TUI.

## Bootstrap

Run the install script on a fresh machine (requires SSH access to GitHub):

```bash
bash install.sh
```

> Since the repo is private, `curl | bash` from `raw.githubusercontent.com` won't work.
> Copy the script manually, host it as a public Gist, or clone the repo first.

The script detects your OS/arch, installs Go if missing, clones the repo, builds the binary, and launches the TUI.

## Quick start

```bash
git clone --recursive git@github.com:ViniZap4/setup.git ~/setup
cd ~/setup
make build
./bin/setup
```

## Architecture

```
~/setup/
├── cmd/setup/         # Go CLI entry point
├── internal/          # Go packages (config, module, symlink, platform, tui)
├── modules/           # Git submodules
│   ├── zsh-config
│   ├── oh-my-zsh-theme-vini4
│   ├── kitty-config
│   ├── yazi-config
│   ├── gitconfig
│   ├── tmux-config
│   ├── nvim-config
│   └── glide-config
├── bat/               # Bat syntax theme files
├── Makefile
└── go.mod
```

## Modules

| Module | Description |
|--------|-------------|
| `zsh-config` | Zsh with Oh My Zsh, fzf, zoxide, eza |
| `oh-my-zsh-theme-vini4` | Custom Powerline prompt theme |
| `kitty-config` | Kitty terminal with Catppuccin theme |
| `yazi-config` | Yazi file manager with nightfly flavor |
| `gitconfig` | Git with delta, catppuccin-mocha |
| `tmux-config` | Tmux with vim panes, catppuccin |
| `nvim-config` | Neovim with lazy.nvim |
| `glide-config` | Glide WM for macOS |

## Usage

### TUI mode (default)

```bash
./bin/setup
```

Navigate: `j/k`, select: `space`, confirm: `enter`, back: `esc`

### CLI mode

```bash
setup status                   # show symlink status
setup install                  # install all modules
setup install zsh-config tmux  # install specific modules
setup link                     # create symlinks only
setup update                   # pull latest submodules
```

## Adding a new module

1. Create a new repo with `module.yaml` and `install.sh`
2. Add as submodule: `git submodule add <url> modules/<name>`
3. The CLI will auto-discover it

### module.yaml format

```yaml
name: my-config
description: What this config does
platforms:
  - macos
  - linux
links:
  - source: config-file
    target: ~/.config/app/config-file
dependencies:
  brew:
    - package-name
```

## Development

```bash
make build    # build binary
make run      # build and run TUI
make status   # build and show status
make tidy     # go mod tidy
make clean    # remove build artifacts
```
