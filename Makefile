.PHONY: all nvim tmux ghostty

# Install nvim, tmux, and ghostty configurations
all: nvim tmux ghostty

# Install neovim configuration to ~/.config/nvim/
nvim:
	mkdir -p ~/.config/nvim
	cp -r nvim/* ~/.config/nvim/
	@echo "Neovim configuration installed to ~/.config/nvim"

# "tmux" target: installs tmux configuration and reloads it if tmux is running
tmux:
	# Copy tmux.conf in this repository to the user's home directory as .tmux.conf
	cp tmux.conf ~/.tmux.conf

	# Print a confirmation message that the configuration was installed
	@echo "Tmux configuration installed to ~/.tmux.conf"

	# If tmux is installed and a tmux server is running, reload the config
	@if command -v tmux >/dev/null 2>&1 && tmux info &>/dev/null; then \
		# Source the new config and print reload message
		tmux source-file ~/.tmux.conf && echo "Tmux configuration reloaded"; \
	else \
		# Otherwise, print a message that tmux is not running and config will load next time
		echo "Tmux is not running, configuration will be loaded on next start"; \
	fi

# Install ghostty configuration
ghostty:
	# Create ghostty config directory if it doesn't exist
	mkdir -p ~/Library/Application\ Support/com.mitchellh.ghostty

	# Copy ghostty config file
	cp ghostty ~/Library/Application\ Support/com.mitchellh.ghostty/config

	# Print confirmation message
	@echo "Ghostty configuration installed to ~/Library/Application Support/com.mitchellh.ghostty/config"

	# Reload ghostty config if ghostty is running (using Cmd+Shift+,)
	@echo "If Ghostty is running, reload config with Cmd+Shift+,"
