local options = vim.opt

-- set termguicolors to enable highlight groups
options.termguicolors = true

options.tabstop = 2
options.shiftwidth = 2

options.clipboard:append("unnamedplus")

options.ignorecase = true
options.smartcase = true

options.relativenumber = true
options.number = true

vim.cmd([[autocmd FileType * set formatoptions-=cro]])
