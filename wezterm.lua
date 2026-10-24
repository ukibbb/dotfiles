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
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.show_tabs_in_tab_bar = true
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 32
config.status_update_interval = 5000
config.use_resize_increments = false
config.window_decorations = "INTEGRATED_BUTTONS | RESIZE | MACOS_FORCE_DISABLE_SHADOW"
config.integrated_title_button_style = "MacOsNative"
config.integrated_title_button_alignment = "Left"
config.integrated_title_buttons = { "Close", "Hide", "Maximize" }
config.window_frame = {
	active_titlebar_bg = "#000000",
	inactive_titlebar_bg = "#000000",
}

-- Tab bar: cyan accent on black.
config.colors.tab_bar = {
	background = "#000000",
	active_tab = { bg_color = "#00d9ff", fg_color = "#000000", intensity = "Bold" },
	inactive_tab = { bg_color = "#000000", fg_color = "#808080" },
	inactive_tab_hover = { bg_color = "#1a1a1a", fg_color = "#e0e0e0" },
}

-- ---------------------------------------------------------------------------
-- Multiplexing
-- ---------------------------------------------------------------------------

config.leader = { key = "s", mods = "CTRL", timeout_milliseconds = 1000 }

local home = os.getenv("HOME")
local herdr = home .. "/.local/bin/herdr"

-- smart-splits.nvim sets the IS_NVIM user var; Ctrl+h/j/k/l then goes to
-- Neovim (which moves between its splits and hands off at the edge).
local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction = { h = "Left", j = "Down", k = "Up", l = "Right" }

local function split_nav(key)
	return {
		key = key,
		mods = "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				win:perform_action(act.SendKey({ key = key, mods = "CTRL" }), pane)
			else
				win:perform_action(act.ActivatePaneDirection(direction[key]), pane)
			end
		end),
	}
end

-- Leader+h/j/k/l resizes, then h/j/k/l keep resizing for 1s.
local function resize(key)
	return {
		key = key,
		mods = "LEADER",
		action = act.Multiple({
			act.AdjustPaneSize({ direction[key], 5 }),
			act.ActivateKeyTable({ name = "resize_pane", one_shot = false, timeout_milliseconds = 1000 }),
		}),
	}
end

config.keys = {
	-- Preserve the terminal sequences already consumed by Neovim.
	{ key = "n", mods = "CMD", action = act.SendString("\x1b[32~") },
	{ key = "j", mods = "CMD", action = act.SendString("\x1b[106;9u") },
	{ key = "k", mods = "CMD", action = act.SendString("\x1b[107;9u") },
	{ key = "h", mods = "CMD", action = act.SendString("\x1b[104;7u") },
	{ key = "l", mods = "CMD", action = act.SendString("\x1b[108;7u") },
	{ key = "q", mods = "CMD", action = act.SendString("\x1b[113;7u") },
	{ key = "\\", mods = "CMD", action = act.SendString("\x1b[92;7u") },
	{ key = "-", mods = "CMD", action = act.SendString("\x1b[45;7u") },

	-- Ctrl+s twice sends Ctrl+s to the application.
	{ key = "s", mods = "LEADER|CTRL", action = act.SendKey({ key = "s", mods = "CTRL" }) },
	-- Repairs a pane after a fullscreen app leaves mouse reporting or alternate screen enabled.
	{
		key = "g",
		mods = "LEADER|CTRL",
		action = act.SendString(
			"printf '\033[?1000l\033[?1002l\033[?1003l\033[?1005l\033[?1006l\033[?1015l\033[?1049l'; stty sane -ixon\r"
		),
	},
	-- Ctrl+l navigates panes, so clear-screen moves under the leader.
	{ key = "l", mods = "LEADER|CTRL", action = act.SendKey({ key = "l", mods = "CTRL" }) },

	-- Splits and panes
	{ key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "m", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	split_nav("h"),
	split_nav("j"),
	split_nav("k"),
	split_nav("l"),
	resize("h"),
	resize("j"),
	resize("k"),
	resize("l"),

	-- Tabs
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{
		key = ",",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Tab name",
			action = wezterm.action_callback(function(win, _, line)
				if line and line ~= "" then
					win:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- Workspaces
	{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	{ key = "j", mods = "LEADER|CTRL", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	{ key = "(", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(-1) },
	{ key = ")", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(1) },

	-- Agents hub: herdr in its own workspace
	{
		key = "a",
		mods = "LEADER",
		action = act.SwitchToWorkspace({ name = "agents", spawn = { args = { herdr }, cwd = home } }),
	},

	-- Copy mode with vi keys, config reload
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "r", mods = "LEADER", action = act.ReloadConfiguration },
}

for i = 1, 9 do
	table.insert(config.keys, { key = tostring(i), mods = "LEADER", action = act.ActivateTab(i - 1) })
end

config.key_tables = {
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 5 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 5 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 5 }) },
		{ key = "Escape", action = "PopKeyTable" },
	},
}

-- `nt` in the shell picks a folder with fzf and sets this user var;
-- switch to (or create) a workspace named after the folder.
wezterm.on("user-var-changed", function(win, pane, name, value)
	if name ~= "wezterm_workspace" or value == "" then
		return
	end
	local workspace = value:match("([^/]+)/?$"):gsub("[.:]", "-")
	win:perform_action(act.SwitchToWorkspace({ name = workspace, spawn = { cwd = value } }), pane)
end)

-- Right status: leader indicator, herdr agents, workspace, time.
wezterm.on("update-status", function(win, _)
	local cells = {}
	if win:leader_is_active() then
		table.insert(cells, { Background = { Color = "#bd93f9" } })
		table.insert(cells, { Foreground = { Color = "#000000" } })
		table.insert(cells, { Text = " ^S " })
		table.insert(cells, "ResetAttributes")
		table.insert(cells, { Text = " " })
	end

	local ok, out = wezterm.run_child_process({ home .. "/.config/herdr/agents-status.sh", "--bar" })
	if ok and out ~= "" then
		table.insert(cells, { Foreground = { Color = "#bd93f9" } })
		table.insert(cells, { Text = out })
	end

	table.insert(cells, { Foreground = { Color = "#00d9ff" } })
	table.insert(cells, { Text = wezterm.nerdfonts.cod_window .. " " .. win:active_workspace() })
	table.insert(cells, { Foreground = { Color = "#808080" } })
	table.insert(cells, { Text = "  " .. wezterm.strftime("%H:%M") .. " " })
	win:set_right_status(wezterm.format(cells))
end)

wezterm.on("gui-startup", function(cmd)
	local _, _, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

return config
