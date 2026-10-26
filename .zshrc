# Avoid macOS's low default descriptor limit for Bun applications.
ulimit -S -n 65536 2>/dev/null || true

if [[ ! -d "${DOTFILES_DIR:-}" ]]; then
  DOTFILES_ZSHRC="${(%):-%x}"
  [[ "$DOTFILES_ZSHRC" != /* ]] && DOTFILES_ZSHRC="$PWD/$DOTFILES_ZSHRC"
  export DOTFILES_DIR="${DOTFILES_ZSHRC:A:h}"
fi

# --- PATH -------------------------------------------------------------------

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if (( $+commands[brew] )); then
  export PATH="$HOMEBREW_PREFIX/opt/libpq/bin:$HOMEBREW_PREFIX/opt/mysql-client/bin:$HOMEBREW_PREFIX/opt/sqlite/bin:$PATH"
fi

# Mason (Neovim LSP/tools) bin directory
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

[ -s "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

export PATH="$HOME/.local/bin:$PATH"

# --- Shell options ----------------------------------------------------------

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt extended_history hist_ignore_dups hist_ignore_space share_history
setopt auto_cd interactive_comments no_beep

export EDITOR=nvim
export VISUAL=nvim

# Supply-chain guard: npm and pip only accept absolute dates, so roll a
# 30-day cutoff at shell start (uv, pnpm, bun and mise use their config files).
export npm_config_before="$(date -u -v-30d +%Y-%m-%d)"
export PIP_UPLOADED_PRIOR_TO="$npm_config_before"

# Ctrl-s is the WezTerm leader; keep terminal flow control from treating it as XOFF.
stty -ixon 2>/dev/null || true

# Emacs-style line editing (ctrl+a/e, alt+b/f) like the oh-my-zsh default.
bindkey -e

# --- Completion -------------------------------------------------------------

autoload -Uz compinit
compinit -C
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
setopt menu_complete   # first TAB inserts the first match and enters the menu
zmodload zsh/complist
bindkey -M menuselect '^[[Z' reverse-menu-complete   # shift+tab goes back

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# --- Tools ------------------------------------------------------------------

# mise: per-project versions of node/go/python (replaces nvm)
(( $+commands[mise] )) && eval "$(mise activate zsh)"

# direnv: loads .envrc when entering a directory
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"

# atuin: searchable history on ctrl+r (up arrow stays the default)
(( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"

# zoxide: remembers visited folders; n/nt list the frequent ones first
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# starship prompt
(( $+commands[starship] )) && eval "$(starship init zsh)"

# fzf: ctrl+t files, alt+c directories; previews with bat/eza
if (( $+commands[fzf] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {}'"
  source <(fzf --zsh)
  # atuin owns ctrl+r
  (( $+commands[atuin] )) && bindkey '^r' atuin-search
fi

# --- Aliases ----------------------------------------------------------------

if (( $+commands[eza] )); then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --git --group-directories-first'
  alias la='eza -la --icons --git --group-directories-first'
  alias lt='eza --tree --level=2 --icons'
fi

if (( $+commands[bat] )); then
  alias cat='bat --paging=never --style=plain'
fi

alias vim='nvim'

# --- Functions --------------------------------------------------------------

# Fast system navigation with fuzzy folder selection
n() {
    local selected
    selected=$("$DOTFILES_DIR/fuzzy/select-folder.sh" "$@")
    if [[ -n "$selected" ]]; then
        cd "$selected" || return 1
    fi
}

# Navigate and switch to/create a WezTerm workspace
nt() {
    local selected
    selected=$("$DOTFILES_DIR/fuzzy/select-folder.sh" "$@")
    if [[ -n "$selected" ]]; then
        (( $+commands[zoxide] )) && zoxide add "$selected"
        "$DOTFILES_DIR/fuzzy/wezterm-workspace.sh" "$selected"
    fi
}

# --- Terminal integration ---------------------------------------------------

# WezTerm shell integration: semantic prompts, working-directory tracking
# (new splits open in the current folder) and user vars.
if [[ "${TERM_PROGRAM:-}" == "WezTerm" ]] && [[ -r /Applications/WezTerm.app/Contents/Resources/wezterm.sh ]]; then
  source /Applications/WezTerm.app/Contents/Resources/wezterm.sh
fi

# Plugins last: syntax highlighting must be sourced at the very end.
[ -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# buliOS launcher
alias bulios='bun ~/.claude/BULIOS/TOOLS/bulios.ts -s ~/.claude/BULIOS/BULIOS_SYSTEM_PROMPT.md'

# Syncthing drzewa buliOS: po restarcie startuje z pierwszym terminalem, gdy nie działa jako usługa
# (na Macu służbowym brew services bywa zablokowane). Bez sparowanego folderu nic nie robi.
if command -v syncthing >/dev/null && [[ -f "$HOME/.config/bulios/USER/.stignore" ]] && ! pgrep -qx syncthing; then
  (nohup syncthing serve --no-browser >"$HOME/Library/Logs/syncthing.log" 2>&1 &)
fi

# Buli (>= 1.8) z tym samym promptem, hookami i stopką buliOS co Claude Code.
if [[ -f ~/.claude/BULIOS/BULIOS_SYSTEM_PROMPT.md && -f ~/.claude/settings.json ]]; then
  alias buli='buli --append-system-prompt-file ~/.claude/BULIOS/BULIOS_SYSTEM_PROMPT.md --settings ~/.claude/settings.json --mcp-config ~/.claude/BULIOS/mcp.json'
fi

# Własne paczki (@ukibbb) są zaufane: aktualizacja Buli bez 30-dniowego bezpiecznika.
buli-update() { env -u npm_config_before npm install -g @ukibbb/buli@latest; }
