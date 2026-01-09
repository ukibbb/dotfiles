.PHONY: nvim

nvim:
	mkdir -p ~/.config/nvim
	cp -r nvim/* ~/.config/nvim/
	@echo "Neovim configuration installed to ~/.config/nvim"
