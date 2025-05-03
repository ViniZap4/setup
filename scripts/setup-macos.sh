#!/usr/bin/env zsh

# ----------------------------------------
# VARIABLES
# ----------------------------------------
BREW_BIN="/opt/homebrew/bin/brew"           # adjust if needed
OH_MY_ZSH_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
DOTFILES_REPO="git@github.com:Vinizap4/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

# ----------------------------------------
# 1. Homebrew
# ----------------------------------------
install_homebrew() {
  if ! command -v brew >/dev/null; then
    echo "➡️  Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$('"${BREW_BIN}"' shellenv)"' >> ~/.zshrc
    eval "$(${BREW_BIN} shellenv)"
  else
    echo "✅ Homebrew already installed; updating..."
    brew update
  fi
}

# ----------------------------------------
# 2. Oh My Zsh (keeps your zshrc alone)
# ----------------------------------------
install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "➡️  Installing Oh My Zsh (won’t overwrite ~/.zshrc)..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL $OH_MY_ZSH_URL)"
  else
    echo "✅ Oh My Zsh already present"
  fi
}

# ----------------------------------------
# 3. Yazi + dependencies
# ----------------------------------------
install_yazi() {
  echo "➡️  Installing Yazi and its dependencies..."
  brew install yazi ffmpeg p7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick

  # (Optional) Nerd font for icons
  brew tap homebrew/cask-fonts
  brew install --cask font-symbols-only-nerd-font
}

# ----------------------------------------
# 4. Neovim, tmux, nvm
# ----------------------------------------
install_editors_and_tmux() {
  echo "➡️  Installing Neovim, tmux, and nvm..."
  brew install neovim tmux nvm gh
}

# ----------------------------------------
# 5. zsh-autosuggestions
# ----------------------------------------
install_zsh_autosuggestions() {
  echo "➡️  Installing zsh-autosuggestions via Homebrew..."
  brew install zsh-autosuggestions
  # your own ~/.zshrc should already source it
}


# ----------------------------------------
# MAIN
# ----------------------------------------
echo "🚀  Starting macOS Zsh environment bootstrap…"

install_homebrew
install_oh_my_zsh
install_yazi
install_editors_and_tmux
install_zsh_autosuggestions

echo
echo "🎉  All done! Restart your terminal or run ‘source ~/.zshrc’ when you’re ready."
