  # --- ZSH CONFIGURATION ---
# Auto-start Hyprland on TTY1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    exec Hyprland
fi

# 1. Enable Starship (The Rust Prompt)
eval "$(starship init zsh)"

# 2. History Settings (Remember what you typed)
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000
setopt SHARE_HISTORY

# 3. Completion (Make Tab key useful)
autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' # Case insensitive tab completion

# 4. Aliases (Shortcuts)
alias ll='ls -l'
alias la='ls -la'
alias v='nvim'           # Type 'v' to open Neovim
alias c='clear'
alias g='git'

alias logout='killall Hyprland' # Force logout

# Arch Specific Shortcuts
alias pac='sudo pacman -S'
alias update='sudo pacman -Syu'
# alias yay='yay'
alias vhc='v ~/.config/hypr/' 
# 5. Environment Variables
export EDITOR='nvim'
export PATH=$PATH:~/.cargo/bin # For Rust tools
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fastfetch

export PATH=$PATH:~/.spicetify
export EDITOR='nvim'
export VISUAL='nvim'
