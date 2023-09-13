return {
	"lunarvim/Onedarker.nvim",
	priority = 1000,
	config = function()
		vim.cmd([[colorscheme onedarker ]])
		vim.cmd([[highlight LineNr guifg=#87CEEB ]])
	end,
}
