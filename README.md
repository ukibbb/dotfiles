# Dotfiles

Personal macOS dotfiles for the terminal/editor stack:

- zsh (no framework) with starship, atuin, autosuggestions and syntax highlighting
- mise for Node/Go/Python versions, direnv, eza, bat, git-delta, btop
- Neovim with lazy.nvim, NvChad UI pieces, LSP, formatting, Telescope, and local plugins
- WezTerm as terminal and multiplexer (workspaces, tabs, splits; tmux-like `Ctrl+s` leader) with macOS `Cmd` key mappings
- Claude Code global settings and status line
- herdr (agent hub in the `agents` WezTerm workspace) and git config

## Documentation

- [Polish WezTerm and Neovim guide](neovim_docs/README.md), split by topic and formatted for printing
- [Terminal tools: how to use them](neovim_docs/06-terminal-tools.md)
- [Herdr and Claude Code](neovim_docs/07-herdr-claude-code.md)

## Fresh Mac Setup

1. Install Homebrew if it is not already installed.

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Clone this repo.

```sh
git clone <repo-url> "$HOME/Desktop/Projekty/dotfiles"
cd "$HOME/Desktop/Projekty/dotfiles"
```

3. Install Homebrew dependencies.

```sh
brew bundle --file Brewfile
```

4. Install Node (and other runtimes) with mise.

```sh
mise install
```

5. Link the dotfiles.

```sh
bash install.sh install
bash install.sh status
```

The installer backs up existing targets as `*.backup.YYYYMMDDHHMMSS` before replacing them.

6. Restart WezTerm so it reads `~/.config/wezterm/wezterm.lua`. Keys: [WezTerm guide](neovim_docs/03-wezterm.md).

7. Bootstrap Neovim.

```sh
nvim --headless "+Lazy! restore" +qa
```

Then open Neovim and install external tools through Mason:

```vim
:MasonInstall lua-language-server pyright ruff typescript-language-server html-lsp css-lsp dockerfile-language-server docker-compose-language-service stylua mypy debugpy delve js-debug-adapter
```

Neovim debugging uses `nvim-dap` with `debugpy` for Python, `delve` for Go, and `js-debug-adapter` for Node and Chrome. Project-specific JavaScript and TypeScript runners can be configured in `.vscode/launch.json` with the `pwa-node` or `pwa-chrome` adapter type.

8. Optional tools.

```sh
curl -fsSL https://claude.ai/install.sh | bash
curl -fsSL https://herdr.dev/install.sh | sh
npm install -g opencode-ai @openai/codex
atuin import zsh
```

Run `claude` once to authenticate. Claude plugins (superpowers + LSPs) are declared in `claude/settings.json`; if they are missing, install them with `claude plugin install superpowers@superpowers-marketplace` (and `typescript-lsp`, `pyright-lsp`, `gopls-lsp`, `lua-lsp` from `claude-plugins-official`).

9. Restart apps.

- Restart WezTerm so it reads `~/.config/wezterm/wezterm.lua`.
- Restart the shell or run `source ~/.zshrc`.

## Reproducible Setup

Keep setup reproducible by treating every machine dependency as declared state:

- Homebrew apps and CLI tools belong in `Brewfile`.
- Neovim plugin versions are pinned in `nvim/lazy-lock.json`.
- Mason packages are listed in this README and should be updated when LSP, formatter, linter, or debugger requirements change.
- Local dotfile links are owned by `install.sh`; run `bash install.sh status` after changes.
- Existing local config should never be silently deleted; the installer creates timestamped backups.
- Paths should use `$HOME`, `~`, or paths resolved from the repo instead of hardcoded usernames.
- App-specific manual steps, like Claude authentication, must be documented here.

When dependencies change:

- Add Homebrew dependencies to `Brewfile`.
- Run `:Lazy sync` intentionally and commit changes to `nvim/lazy-lock.json` when Neovim plugins should be upgraded.
- Update the Mason package list in this README when external Neovim tools change.
- Run `bash install.sh install` twice; the second run should report existing links and no new backups.

For exact recreation on a new Mac:

```sh
cd "$HOME/Desktop/Projekty/dotfiles"
brew bundle --file Brewfile
bash install.sh install
mise install
nvim --headless "+Lazy! restore" +qa
```

Then install the Mason package list above and verify with:

```sh
bash install.sh status
nvim --headless "+checkhealth" +qa
wezterm show-keys > /dev/null
```

## Uninstall

```sh
bash install.sh uninstall
```

This removes symlinks managed by the installer. It does not remove backups, Homebrew packages, or Neovim data.
