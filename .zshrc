export ZSH="$HOME/.oh-my-zsh"

if [[ -z "${DOTFILES_DIR:-}" ]]; then
  DOTFILES_ZSHRC="${(%):-%x}"
  [[ "$DOTFILES_ZSHRC" != /* ]] && DOTFILES_ZSHRC="$PWD/$DOTFILES_ZSHRC"
  export DOTFILES_DIR="${DOTFILES_ZSHRC:A:h}"
fi


ZSH_THEME="robbyrussell"


zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' frequency 14

# Uncomment the following line if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# Mason (Neovim LSP/tools) bin directory
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

# Go toolchain installed by the official macOS installer
export PATH="/usr/local/go/bin:$PATH"

# Go tools installed by `go install` (gopls, goimports, dlv, etc.)
if command -v go >/dev/null 2>&1; then
  export PATH="$(go env GOPATH)/bin:$PATH"
fi

# DISABLED: No longer needed — fs_event watcher in autocmds.lua replaced hook-based approach
# Start Neovim with server socket for Claude Code integration
# Socket named by directory; multiple instances get numbered suffix
# Claude hook broadcasts to all instances that have the file loaded
# unalias nvim 2>/dev/null
# nvim() {
#     local dir_slug=$(pwd | tr '/' '_')
#     local base="/tmp/nvim${dir_slug}"
#     local sock="${base}.sock"
#     local i=1
#
#     # Find available socket (remove stale ones, skip active ones)
#     while [[ -S "$sock" ]]; do
#         if command nvim --server "$sock" --remote-expr "1" &>/dev/null; then
#             sock="${base}_${i}.sock"
#             ((i++))
#         else
#             rm -f "$sock"
#             break
#         fi
#     done
#
#     command nvim --listen "$sock" "$@"
#     # Clean up socket on exit
#     rm -f "$sock"
# }

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

[ -s "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Fast system navigation with fuzzy folder selection
n() {
    local selected
    selected=$("$DOTFILES_DIR/fuzzy/select-folder.sh" "$@")
    if [[ -n "$selected" ]]; then
        cd "$selected" || return 1
    fi
}

# Navigate and create/attach to tmux session
nt() {
    local selected
    selected=$("$DOTFILES_DIR/fuzzy/select-folder.sh" "$@")
    if [[ -n "$selected" ]]; then
        "$DOTFILES_DIR/fuzzy/tmux-session.sh" "$selected"
    fi
}

# Ctrl-s is the tmux prefix; keep terminal flow control from treating it as XOFF.
stty -ixon 2>/dev/null || true

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
