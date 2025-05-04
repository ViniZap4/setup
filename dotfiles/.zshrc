# ──────────────────────────── Profile ────────────────────────────
#zmodload zsh/zprof

# ───────────────────── Oh My Zsh Core setup ──────────────────────
export ZSH="$HOME/.oh-my-zsh"
export PATH="/opt/homebrew/bin:$PATH"
ZSH_THEME="vini4"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# ──────────────────────── Lazy-load NVM ──────────────────────────
export NVM_DIR="$HOME/.nvm"
autoload -U add-zsh-hook
load_nvm() {
  unset -f load_nvm
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \
      . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
}
add-zsh-hook chpwd   load_nvm
add-zsh-hook preexec load_nvm

# ─────────────────────────── fzf setup ───────────────────────────
eval "$(fzf --zsh)"

export FZF_DEFAULT_OPTS="--height 50% --layout=default --border --color=hl:#2dd4bf"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"

# ────────────────────────── Zoxide setup ─────────────────────────
eval "$(zoxide init zsh)"

# ───────────────────── Fast completion setup ─────────────────────
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ~/.zsh/cache
compinit -C -i

# ──────────────────────────── bat setup ──────────────────────────
export BAT_THEME="tokyonight_night"

# ───────────────────────────── Aliases ───────────────────────────

# nvim
alias n="nvim"
alias n.="nvim ."
# npm
alias nrd="npm run dev"
alias nrt="npm run test"
alias nrs="npm run storybook"
alias ni="npm install"
# tmux
alias t="tmux"
alias ta="tmux attach -t"
alias tls="tmux ls"
alias tn="tmux new -t"
# eza
alias e='eza -lha --icons --color=always --git'
alias et='eza -lha --icons --color=always --tree --level=3 -I .git'
alias eta='eza -lha --icons --color=always --tree'

# ───────────────────────────── setting ───────────────────────────

# set default editor - yazi
export EDITOR=nvim


# add zsh-autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# ──────────────────────────── run Custom ──────────────────────────
if [ -d "$HOME/setup/custom/.zshrc" ]; then
	source ~/setup/custom/.zshrc
fi

# ─────────────────────────── Show timings ────────────────────────
#zprof
