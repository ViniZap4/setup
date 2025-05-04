#!/usr/bin/env zsh
# ----------------------------------------
# LINUX Zsh Environment Bootstrap
# ----------------------------------------

# ---------
# COLORS
# ---------
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# ---------
# SPINNER
# ---------
spinner() {
  local pid=$1 msg=$2
  local delay=0.1 spinstr='|/-\'
  while kill -0 $pid 2>/dev/null; do
    for c in $spinstr; do
      echo -ne "\r${BLUE}$c${RESET} $msg..."
      sleep $delay
    done
  done
  echo -ne "\r"
}

# ---------
# RUN WITH RETRIES & PROGRESS
# ---------
CURRENT=0
TOTAL=6
run_step() {
  local desc=$1; shift
  ((CURRENT++))
  echo "${BOLD}Step $CURRENT/$TOTAL:${RESET} $desc"
  local tries=0 max=3
  while (( tries < max )); do
    "$@" & spinner $! "$desc"
    wait $!; status=$?
    if (( status == 0 )); then
      echo "${GREEN}✔${RESET} $desc succeeded"
      return 0
    else
      ((tries++))
      echo "${YELLOW}⚠ $desc failed ($tries/$max)${RESET}"
      (( tries < max )) && echo "   Retrying..."
    fi
  done
  echo "${RED}✖ Giving up on '$desc'${RESET}"
  return 1
}

# ---------
# DETECT DISTRO & PACKAGE CMDS
# ---------
if [[ -r /etc/os-release ]]; then
  source /etc/os-release
else
  echo "${RED}Cannot detect distribution (no /etc/os-release)${RESET}"
  exit 1
fi

case "$ID" in
  ubuntu|debian|pop)
    INSTALL="sudo apt update && sudo apt install -y"
    UPDATE="sudo apt update && sudo apt upgrade -y"
    PKGS_DEP=(cargo ffmpeg p7zip jq poppler-utils fd-find ripgrep fzf zoxide resvg imagemagick)
    PKGS_OTH=(neovim tmux git curl)  # nvm & gh via upstream scripts
    ;;
  arch)
    INSTALL="sudo pacman -Sy --noconfirm"
    UPDATE="sudo pacman -Syu --noconfirm"
    PKGS_DEP=(rust ffmpeg p7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick)
    PKGS_OTH=(neovim tmux git curl)
    ;;
  opensuse*|suse)
    INSTALL="sudo zypper install -y"
    UPDATE="sudo zypper update -y"
    PKGS_DEP=(rust ffmpeg p7zip jq poppler-utils fd-find ripgrep fzf zoxide librsvg-tools ImageMagick)
    PKGS_OTH=(neovim tmux git curl)
    ;;
  nixos)
    INSTALL_NIX="nix-env -iA nixpkgs"
    UPDATE_NIX="nix-env -u"
    PKGS_DEP=(rustc ffmpeg p7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick)
    PKGS_OTH=(neovim tmux git curl)
    ;;
  *)
    echo "${RED}Unsupported distro: $ID${RESET}"
    exit 1
    ;;
esac

echo "${BOLD}${BLUE}🚀  Starting Linux Zsh environment bootstrap…${RESET}"
echo

# 1) Update OS packages
if [[ -n $UPDATE ]]; then
  run_step "Updating system packages" $UPDATE
elif [[ -n $UPDATE_NIX ]]; then
  run_step "Updating Nix packages" $UPDATE_NIX
fi
echo

# 2) Install dependencies
if [[ -n $INSTALL ]]; then
  if command -v "${PKGS_DEP[1]}" &>/dev/null; then
    read -q "?Dependencies already seem installed. Reinstall/upgrade? (y/N) " yn; echo
    if [[ $yn =~ ^[Yy]$ ]]; then
      run_step "Installing dependencies" $INSTALL ${PKGS_DEP[@]}
    else
      echo "→ Skipping dependencies."
    fi
  else
    run_step "Installing dependencies" $INSTALL ${PKGS_DEP[@]}
  fi
else
  run_step "Installing dependencies via Nix" $INSTALL_NIX ${PKGS_DEP[@]/#/nixpkgs.}
fi
echo

# 3) Install Yazi (via cargo)
if command -v yazi &>/dev/null; then
  read -q "?Yazi already installed. Update via cargo? (y/N) " yn; echo
  if [[ $yn =~ ^[Yy]$ ]]; then
    run_step "Updating Yazi" cargo install --force yazi
  else
    echo "→ Skipping Yazi."
  fi
else
  run_step "Installing Yazi" cargo install yazi
fi
echo

# 4) Oh My Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  read -q "?Oh My Zsh present. Run upgrade? (y/N) " yn; echo
  if [[ $yn =~ ^[Yy]$ ]]; then
    run_step "Upgrading Oh My Zsh" sh "${ZSH:-$HOME/.oh-my-zsh}/tools/upgrade.sh"
  else
    echo "→ Skipping Oh My Zsh."
  fi
else
  run_step "Installing Oh My Zsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
echo

# 5) Neovim, tmux, nvm & GitHub CLI
#  - distros install neovim/tmux via package manager
#  - nvm & gh via their official install scripts
RUN_PKG_STEP() {
  if [[ -n $INSTALL ]]; then
    run_step "Installing ${PKGS_OTH[*]}" $INSTALL ${PKGS_OTH[@]}
  else
    run_step "Installing ${PKGS_OTH[*]} via Nix" $INSTALL_NIX ${PKGS_OTH[@]/#/nixpkgs.}
  fi
}
if command -v neovim &>/dev/null || command -v nvim &>/dev/null; then
  read -q "?Neovim/tmux/etc present. Upgrade? (y/N) " yn; echo
  if [[ $yn =~ ^[Yy]$ ]]; then
    if [[ -n $UPDATE ]]; then
      run_step "Upgrading Neovim & tmux" $UPDATE ${PKGS_OTH[@]}
    elif [[ -n $UPDATE_NIX ]]; then
      run_step "Upgrading Neovim & tmux via Nix" $UPDATE_NIX
    else
      RUN_PKG_STEP
    fi
  else
    echo "→ Skipping Neovim/tmux."
  fi
else
  RUN_PKG_STEP
fi

#  nvm
if [[ -d "$HOME/.nvm" ]]; then
  echo "→ nvm already installed"
else
  run_step "Installing nvm" sh -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh)"
fi
#  gh
if command -v gh &>/dev/null; then
  echo "→ GitHub CLI already installed"
else
  run_step "Installing GitHub CLI" sh -c "$(curl -fsSL https://cli.github.com/install.sh)"
fi
echo

# 6) zsh-autosuggestions
if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
  echo "→ zsh-autosuggestions present"
else
  run_step "Installing zsh-autosuggestions" git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
fi
echo

echo "${GREEN}${BOLD}🎉  All done!${RESET}"
echo "Restart your shell or run ‘source ~/.zshrc’ to apply."
