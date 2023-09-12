return {
	"navarasu/onedark.nvim",
	priority = 1000,
	config = function()
		vim.cmd([[colorscheme onedark ]])
		vim.cmd([[highlight LineNr guifg=#87CEEB ]])
	end,
}
