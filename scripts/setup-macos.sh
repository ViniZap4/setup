#!/usr/bin/env zsh

# ----------------------------------------
# COLORS & FORMATTING
# ----------------------------------------
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# ----------------------------------------
# SPINNER FUNCTION
# ----------------------------------------
spinner() {
  local pid=$1
  local msg=$2
  local delay=0.1
  local spinstr='|/-\'
  while kill -0 "$pid" 2>/dev/null; do
    for c in $spinstr; do
      echo -ne "\r${BLUE}$c${RESET} $msg..."
      sleep $delay
    done
  done
  echo -ne "\r"
}

# ----------------------------------------
# RUN A STEP WITH RETRIES & PROGRESS
# ----------------------------------------
CURRENT_STEP=0
TOTAL_STEPS=5

run_step() {
  local desc="$1"; shift
  local cmd=("$@")
  ((CURRENT_STEP++))
  echo "${BOLD}Step $CURRENT_STEP/$TOTAL_STEPS:${RESET} $desc"

  local retries=0
  local max_retries=3

  while (( retries < max_retries )); do
    "${cmd[@]}" &   # start in background
    spinner $! "$desc"
    wait $!
    local status=$?

    if (( status == 0 )); then
      echo "${GREEN}✔${RESET} $desc succeeded"
      return 0
    else
      ((retries++))
      echo "${YELLOW}⚠ Attempt $retries/$max_retries failed for '$desc'${RESET}"
      if (( retries < max_retries )); then
        echo "   Retrying..."
      else
        echo "${RED}✖ Giving up on '$desc' and moving on.${RESET}"
      fi
    fi
  done

  return 1
}

# ----------------------------------------
# MAIN INSTALLATION SEQUENCE
# ----------------------------------------
echo "${BOLD}${BLUE}🚀  Starting macOS Zsh environment bootstrap…${RESET}"
echo

# 1) Homebrew
if ! command -v brew &>/dev/null; then
  run_step "Installing Homebrew" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  read -q "?Homebrew is already installed. Update it? (y/N) " yn; echo
  if [[ $yn =~ ^[Yy]$ ]]; then
    run_step "Updating Homebrew" brew update
  else
    echo "→ Skipping Homebrew update."
  fi
fi
echo

# 2) Yazi + dependencies
deps=(yazi ffmpeg p7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick)
if brew list yazi &>/dev/null; then
  read -q "?Yazi & dependencies already installed. Upgrade them? (y/N) " yn; echo
  if [[ $yn =~ ^[Yy]$ ]]; then
    run_step "Upgrading Yazi & dependencies" brew upgrade yazi ${deps[@]:1}
  else
    echo "→ Skipping Yazi & dependencies upgrade."
  fi
else
  run_step "Installing Yazi & dependencies" brew install ${deps[@]}
fi
echo


# 3) eza
if brew list eza &>/dev/null; then
  read -q "?eza already installed. Upgrade them? (y/N) " yn; echo
  if [[ $yn =~ ^[Yy]$ ]]; then
    run_step "Upgrading eza" brew upgrade eza
  else
    echo "→ Skipping eza upgrade."
  fi
else
  run_step "Installing eza" brew install eza
fi
echo

# 4) Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
  read -q "?Oh My Zsh is already present. Update it? (y/N) " yn; echo
  if [[ $yn =~ ^[Yy]$ ]]; then
    run_step "Updating Oh My Zsh" sh "${ZSH:-$HOME/.oh-my-zsh}/tools/upgrade.sh"
  else
    echo "→ Skipping Oh My Zsh update."
  fi
else
  run_step "Installing Oh My Zsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
echo

# 5) Neovim, tmux, nvm, GitHub CLI
pkgs=(neovim tmux nvm gh)
any_installed=false
for p in ${pkgs[@]}; do
  if brew list $p &>/dev/null; then any_installed=true; break; fi
done

if $any_installed; then
  read -q "?Neovim, tmux, nvm, or gh already installed. Upgrade them? (y/N) " yn; echo
  if [[ $yn =~ ^[Yy]$ ]]; then
    run_step "Upgrading Neovim, tmux, nvm & GitHub CLI" brew upgrade ${pkgs[@]}
  else
    echo "→ Skipping upgrade of Neovim/tmux/nvm/gh."
  fi
else
  run_step "Installing Neovim, tmux, nvm & GitHub CLI" brew install ${pkgs[@]}
fi
echo

# 6) zsh-autosuggestions
if brew list zsh-autosuggestions &>/dev/null; then
  read -q "?zsh-autosuggestions already installed. Upgrade it? (y/N) " yn; echo
  if [[ $yn =~ ^[Yy]$ ]]; then
    run_step "Upgrading zsh-autosuggestions" brew upgrade zsh-autosuggestions
  else
    echo "→ Skipping zsh-autosuggestions upgrade."
  fi
else
  run_step "Installing zsh-autosuggestions" brew install zsh-autosuggestions
fi
echo

echo "${GREEN}${BOLD}🎉 All done!${RESET}  Restart your terminal or run ${BOLD}source ~/.zshrc${RESET} to apply changes."
