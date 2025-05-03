
# Fig “pre” block
if [[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]]; then
  source "$HOME/.fig/shell/zshrc.pre.zsh"
fi

# Android SDK
if [[ -d "$HOME/Library/Android/sdk" ]]; then
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  export PATH="$PATH:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"
fi

# Flutter SDK
if [[ -d "$HOME/Dev/flutter/bin" ]]; then
  export PATH="$HOME/Dev/flutter/bin:$PATH"
fi

# Barrier.app
if [[ -d "/Applications/Barrier.app/Contents/MacOS" ]]; then
  export PATH="/Applications/Barrier.app/Contents/MacOS:$PATH"
fi

# Love2D.app
if [[ -d "/Applications/love.app/Contents/MacOS" ]]; then
  export PATH="/Applications/love.app/Contents/MacOS:$PATH"
fi
