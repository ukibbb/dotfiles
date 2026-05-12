# Dotfiles

Personal macOS dotfiles for the terminal/editor stack:

- zsh and Oh My Zsh
- Neovim with lazy.nvim, NvChad UI pieces, LSP, formatting, Telescope, and local plugins
- tmux with TPM plugins
- Ghostty terminal config
- Karabiner key remaps for Ghostty
- Claude Code global settings and status line

## Fresh Mac Setup

1. Install Homebrew if it is not already installed.

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Clone this repo.

```sh
git clone <repo-url> "$HOME/Desktop/dotfiles"
cd "$HOME/Desktop/dotfiles"
```

3. Install Homebrew dependencies.

```sh
brew bundle --file Brewfile
```

`karabiner-elements` is a pkg-based cask and may ask for an interactive sudo password. If automation cannot install it, run the same `brew bundle` command in a local terminal and enter your password there.

4. Install nvm if `~/.nvm/nvm.sh` does not exist.

```sh
if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
```

5. Link the dotfiles.

```sh
bash install.sh install
bash install.sh status
```

The installer backs up existing targets as `*.backup.YYYYMMDDHHMMSS` before replacing them.

6. Install tmux plugins.

```sh
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
tmux source-file "$HOME/.tmux.conf"
```

Inside tmux, press `Ctrl+s` then `I` to install configured plugins.

7. Bootstrap Neovim.

```sh
nvim --headless "+Lazy! restore" +qa
```

Then open Neovim and install external tools through Mason:

```vim
:MasonInstall lua-language-server pyright ruff typescript-language-server html-lsp css-lsp dockerfile-language-server docker-compose-language-service stylua mypy
```

8. Optional tools.

```sh
npm install -g @anthropic-ai/claude-code
npm install -g opencode-ai
```

Run `claude` once to authenticate if you use Claude Code.

9. Restart apps.

- Restart Ghostty so it reads `~/.config/ghostty/config`.
- Open Karabiner-Elements and approve macOS permissions.
- Restart the shell or run `source ~/.zshrc`.

## Reproducible Setup

Keep setup reproducible by treating every machine dependency as declared state:

- Homebrew apps and CLI tools belong in `Brewfile`.
- Neovim plugin versions are pinned in `nvim/lazy-lock.json`.
- Mason packages are listed in this README and should be updated when LSP, formatter, or linter requirements change.
- Local dotfile links are owned by `install.sh`; run `bash install.sh status` after changes.
- Existing local config should never be silently deleted; the installer creates timestamped backups.
- Paths should use `$HOME`, `~`, or paths resolved from the repo instead of hardcoded usernames.
- App-specific manual steps, like Karabiner permissions and Claude authentication, must be documented here.

When dependencies change:

- Add Homebrew dependencies to `Brewfile`.
- Run `:Lazy sync` intentionally and commit changes to `nvim/lazy-lock.json` when Neovim plugins should be upgraded.
- Update the Mason package list in this README when LSP, formatter, or linter tools change.
- Run `bash install.sh install` twice; the second run should report existing links and no new backups.

For exact recreation on a new Mac:

```sh
cd "$HOME/Desktop/dotfiles"
brew bundle --file Brewfile
bash install.sh install
nvim --headless "+Lazy! restore" +qa
```

Then install the Mason package list above and verify with:

```sh
bash install.sh status
nvim --headless "+checkhealth" +qa
tmux source-file "$HOME/.tmux.conf"
```

## Uninstall

```sh
bash install.sh uninstall
```

This removes symlinks managed by the installer. It does not remove backups, copied Karabiner config, Homebrew packages, Neovim data, or tmux plugins.
