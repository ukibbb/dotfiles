local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local config = wezterm.config_builder()
config:set_strict_mode(true)

config.term = "xterm-256color"
config.font_size = 14.0
config.default_cursor_style = "SteadyBlock"

config.colors = {
	foreground = "#e0e0e0",
	background = "#000000",
	cursor_bg = "#00d9ff",
	cursor_fg = "#000000",
	cursor_border = "#00d9ff",
	selection_fg = "#ffffff",
	selection_bg = "#2a4a7a",
	ansi = {
		"#1a1a1a",
		"#ff5555",
		"#50fa7b",
		"#f1fa8c",
		"#569cd6",
		"#bd93f9",
		"#00d9ff",
		"#e0e0e0",
	},
	brights = {
		"#4d4d4d",
		"#ff6e6e",
		"#69ff94",
		"#ffffa5",
		"#6fa8dc",
		"#d6acff",
		"#4dffff",
		"#ffffff",
	},
}

config.window_padding = {
	left = 8,
	right = 8,
	top = 6,
	bottom = 0,
}
config.enable_tab_bar = true
config.show_tabs_in_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.use_resize_increments = false
config.window_decorations = "INTEGRATED_BUTTONS | RESIZE | MACOS_FORCE_DISABLE_SHADOW"
config.integrated_title_button_style = "MacOsNative"
config.integrated_title_button_alignment = "Left"
config.integrated_title_buttons = { "Close", "Hide", "Maximize" }
config.window_frame = {
	active_titlebar_bg = "#000000",
	inactive_titlebar_bg = "#000000",
}

-- Preserve the terminal sequences already consumed by tmux and Neovim.
config.keys = {
	{ key = "n", mods = "CMD", action = act.SendString("\x1b[32~") },
	{ key = "j", mods = "CMD", action = act.SendString("\x1b[106;9u") },
	{ key = "k", mods = "CMD", action = act.SendString("\x1b[107;9u") },
	{ key = "h", mods = "CMD", action = act.SendString("\x1b[104;7u") },
	{ key = "l", mods = "CMD", action = act.SendString("\x1b[108;7u") },
	{ key = "q", mods = "CMD", action = act.SendString("\x1b[113;7u") },
	{ key = "\\", mods = "CMD", action = act.SendString("\x1b[92;7u") },
	{ key = "-", mods = "CMD", action = act.SendString("\x1b[45;7u") },
}

wezterm.on("gui-startup", function(cmd)
	local _, _, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

return config
