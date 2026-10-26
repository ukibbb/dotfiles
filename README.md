# Dotfiles

Personal macOS dotfiles for the terminal/editor stack:

- zsh (no framework) with starship, atuin, autosuggestions and syntax highlighting
- mise for Node/Go/Python versions, direnv, eza, bat, git-delta, btop
- Neovim with lazy.nvim, NvChad UI pieces, LSP, formatting, Telescope, and local plugins
- WezTerm as terminal and multiplexer (workspaces, tabs, splits; `Ctrl+s` leader) with macOS `Cmd` key mappings
- Claude Code global settings and status line
- herdr (agent hub in the `agents` WezTerm workspace) and git config
- Supply-chain guard: uv, pnpm, bun, mise, npm and pip skip package versions published in the last 30 days

## Documentation

- [Polish WezTerm and Neovim guide](neovim_docs/README.md), split by topic and formatted for printing
- [Terminal tools: how to use them](neovim_docs/06-terminal-tools.md)
- [Herdr and Claude Code](neovim_docs/07-herdr-claude-code.md)

## Fresh Mac Setup

Quick path: clone the repo and run `bash install.sh bootstrap`. It installs Homebrew if missing, runs `brew bundle`, links the dotfiles, runs `mise install` and restores Neovim plugins. Then continue from step 7 (Mason) and step 8 (optional tools).

Manual steps:

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

Run `herdr integration install claude` so the Claude hook in `claude/settings.json` (`~/.claude/hooks/herdr-agent-state.sh`) exists.

Run `claude` once to authenticate. Claude plugins (superpowers + LSPs) are declared in `claude/settings.json`; if they are missing, install them with `claude plugin install superpowers@superpowers-marketplace` (and `typescript-lsp`, `pyright-lsp`, `gopls-lsp`, `lua-lsp` from `claude-plugins-official`).

9. Restart apps.

- Restart WezTerm so it reads `~/.config/wezterm/wezterm.lua`.
- Restart the shell or run `source ~/.zshrc`.

## Second Mac (same buliOS, same memory)

`bash install.sh bootstrap` also clones the private buliOS repo (via `gh`), links its hooks, skills and tools into `~/.claude`, runs `bun install` there and starts Syncthing. Your data is not in this repo: the buliOS tree (`~/.config/bulios/USER`: profile, TELOS, knowledge, ISA, and Claude Code project memories in `CLAUDE_MEMORY/`) comes from the server over Syncthing.

1. Sign in: 1Password app (enable CLI integration), `gh auth login`, `claude` (the Claude account brings claude.ai skills; plugins come from `claude/settings.json`).
2. Run `bash install.sh bootstrap`.
3. Pair Syncthing with the server. `syncthing cli show system` prints this Mac's `myID`; on the server run `st config devices add --device-id <ID> --name <mac>` and `st config folders bulios-user devices add --device-id <ID>`. On this Mac add the server (`syncthing cli config devices add --device-id <server ID>`, shown by `st show system` on the server), accept the `bulios-user` folder at `~/.config/bulios/USER`, and copy `deploy/stignore` from the buliOS repo to `~/.config/bulios/USER/.stignore`.
4. When the tree has arrived, run `bash install.sh install` again so project memories link into `~/.claude/projects/*/memory`.
5. Per-machine state that does not travel: an SSH key for the server (`ssh-keygen`, add the public key on the server), the `novibe` MCP server (`claude mcp add`, then sign in via `/mcp`), and uncommitted local edits in `claude/settings.json`.

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
