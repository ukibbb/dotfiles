local options = vim.opt

options.relativenumber = true
options.number = true

-- set termguicolors to enable highlight groups
options.termguicolors = true

options.tabstop = 2
options.shiftwidth = 2
-- options.expandtab = true
-- options.autoindent = true

options.smartindent = true
options.wrap = true

options.clipboard:append("unnamedplus")

options.ignorecase = true -- ignore case when searching
options.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

options.swapfile = false
options.backup = false

-- options.scrolloff = 8

vim.cmd([[autocmd FileType * set formatoptions-=cro]])
