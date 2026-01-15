.PHONY: all nvim tmux ghostty hammer

# Install nvim, tmux, ghostty, and hammerspoon configurations
all: nvim tmux ghostty hammer

# Install neovim configuration to ~/.config/nvim/
nvim:
	mkdir -p ~/.config/nvim
	cp -r nvim/* ~/.config/nvim/
	@echo "Neovim configuration installed to ~/.config/nvim"

# "tmux" target: installs TPM, tmux configuration and reloads it if tmux is running
tmux:
	@if [ ! -d ~/.tmux/plugins/tpm ]; then \
		echo "Installing Tmux Plugin Manager (TPM)..."; \
		git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm; \
	fi
	cp tmux.conf ~/.tmux.conf
	@echo "Tmux configuration installed to ~/.tmux.conf"
	@if command -v tmux >/dev/null 2>&1 && tmux info &>/dev/null; then \
		echo "Installing tmux plugins..."; \
		tmux source-file ~/.tmux.conf; \
		~/.tmux/plugins/tpm/bin/install_plugins; \
		echo "Tmux configuration reloaded"; \
	else \
		echo "Start tmux and press prefix + I (Ctrl-a then Shift-i) to install plugins"; \
	fi

# Install ghostty configuration
ghostty:
	mkdir -p ~/Library/Application\ Support/com.mitchellh.ghostty
	cp ghostty ~/Library/Application\ Support/com.mitchellh.ghostty/config
	@echo "Ghostty configuration installed to ~/Library/Application Support/com.mitchellh.ghostty/config"
	@echo "If Ghostty is running, reload config with Cmd+Shift+,"

# Install hammerspoon configuration and reload
hammer:
	mkdir -p ~/.hammerspoon
	cp fuzzy/hammerspoon-init.lua ~/.hammerspoon/init.lua
	@echo "Hammerspoon configuration installed to ~/.hammerspoon/init.lua"
	@if command -v hs >/dev/null 2>&1 && hs -c "hs.reload()" 2>/dev/null; then \
		echo "✓ Hammerspoon configuration reloaded"; \
	elif osascript -e 'tell application "System Events" to (name of processes) contains "Hammerspoon"' 2>/dev/null | grep -q "true"; then \
		echo "Note: Reload Hammerspoon manually with Cmd+Ctrl+R to enable IPC"; \
	else \
		echo "Hammerspoon is not running, configuration will be loaded on next start"; \
	fi

# open -a Hammerspoon