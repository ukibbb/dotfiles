--------------------------------------------------------------------------------
-- claude.output_drawer
--
-- This module renders a richer answer viewer using Volt for the frame and a
-- normal read-only buffer for the main content body.
--
-- Owns:
--   - Drawer window geometry and lifecycle
--   - Volt header/tabs/footer rendering
--   - Switching between Answer / Question / Files tabs
--   - Body-buffer actions like insert comments, copy, open full buffer, and close
--
-- Does NOT own:
--   - Fetching Claude answers
--   - Comment insertion logic itself
--   - The legacy scratch fallback implementation
--
-- Why a hybrid viewer:
-- Volt is great at chrome, actions, and structure. A normal body buffer is still
-- better for long-form reading, wrapping, motions, and file lists. This module
-- combines both instead of forcing the whole answer into a single rendering model.
--------------------------------------------------------------------------------

local ok_ui, ui = pcall(require, "volt.ui")
local ok_volt, volt = pcall(require, "volt")
local ok_events, volt_events = pcall(require, "volt.events")

local M = {}

local TABS = { "Answer", "Question", "Files" }
local viewers = {}
local current_viewer = nil
local close_viewer
local switch_tab

local function can_render()
  return ok_ui and ok_volt
end

local function clamp(value, min_value, max_value)
  return math.max(min_value, math.min(max_value, value))
end

local function tab_name(viewer)
  return TABS[viewer.tab_index]
end

local function truncate_middle(text, max_width)
  if vim.fn.strdisplaywidth(text) <= max_width then
    return text
  end

  local target = math.max(6, max_width - 1)
  local left = math.floor(target / 2)
  local right = target - left

  return text:sub(1, left) .. "…" .. text:sub(-right)
end

local function drawer_size(config)
  local width = math.floor(vim.o.columns * config.answers.width_ratio)
  width = clamp(width, config.answers.min_width, config.answers.max_width)

  local height = vim.o.lines - (config.answers.margin * 2) - 2
  height = math.max(config.answers.min_height, height)

  return width, height
end

local function drawer_position(config, width, height)
  local row = config.answers.margin
  local col = vim.o.columns - width - config.answers.margin - 1

  return {
    row = math.max(0, row),
    col = math.max(0, col),
    width = width,
    height = height,
  }
end

local function body_geometry(viewer)
  local top_rows = 5
  local footer_rows = 1

  return {
    row = viewer.spec.row + top_rows,
    col = viewer.spec.col + 1,
    width = viewer.spec.width - 2,
    height = viewer.spec.height - top_rows - footer_rows,
  }
end

local function non_drawer_target_win(viewer)
  local preferred = viewer.record.context and viewer.record.context.source_win or nil

  if preferred
    and vim.api.nvim_win_is_valid(preferred)
    and preferred ~= viewer.body_win
    and preferred ~= viewer.shell_win
  then
    return preferred
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= viewer.body_win and win ~= viewer.shell_win then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype == "" then
        return win
      end
    end
  end
end

local function body_lines_for_tab(viewer)
  local record = viewer.record
  local active = tab_name(viewer)

  if active == "Question" then
    viewer.file_line_map = nil
    return vim.split(record.question, "\n", { plain = true }), "markdown", true
  end

  if active == "Files" then
    local lines = {}
    viewer.file_line_map = {}

    if #record.consulted_files == 0 then
      lines = {
        "Consulted Files",
        "",
        "Claude did not report any consulted files for this answer.",
      }
      return lines, "text", false
    end

    lines[#lines + 1] = string.format("Consulted Files (%d)", #record.consulted_files)
    lines[#lines + 1] = ""

    for i, path in ipairs(record.consulted_files) do
      lines[#lines + 1] = string.format("%d  󰈔  %s", i, path)
      viewer.file_line_map[#lines] = path
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "Press <Enter> to preview the selected file in a split."

    return lines, "text", false
  end

  local lines = {}
  if record.submit_mode == "comment_now" then
    lines[#lines + 1] = "Comment-now mode could not apply comments safely."
    lines[#lines + 1] = "Use I to retry after fixing the file state, or review the answer below."
    lines[#lines + 1] = ""
  end

  if record.answer ~= "" then
    vim.list_extend(lines, vim.split(record.answer, "\n", { plain = true }))
  else
    lines[#lines + 1] = "[No answer returned]"
  end

  viewer.file_line_map = nil
  return lines, "markdown", true
end

local function apply_range_highlight(buf, ns, row, text, hl)
  if text == nil or text == "" then
    return
  end

  vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
    end_col = #text,
    hl_group = hl,
  })
end

local function apply_body_highlights(viewer, lines)
  local hl = viewer.config.answers.highlights
  local active = tab_name(viewer)

  vim.api.nvim_buf_clear_namespace(viewer.body_buf, viewer.body_ns, 0, -1)

  if active == "Files" then
    apply_range_highlight(viewer.body_buf, viewer.body_ns, 0, lines[1], hl.title)

    for line_no, _ in pairs(viewer.file_line_map or {}) do
      apply_range_highlight(viewer.body_buf, viewer.body_ns, line_no - 1, lines[line_no], hl.file)
    end

    apply_range_highlight(viewer.body_buf, viewer.body_ns, #lines - 1, lines[#lines], hl.footer)
    return
  end

  if active == "Answer" and viewer.record.submit_mode == "comment_now" then
    apply_range_highlight(viewer.body_buf, viewer.body_ns, 0, lines[1], hl.warning)
    apply_range_highlight(viewer.body_buf, viewer.body_ns, 1, lines[2], hl.meta)
  end
end

local function render_body(viewer)
  local lines, filetype, wrap = body_lines_for_tab(viewer)

  vim.bo[viewer.body_buf].modifiable = true
  vim.api.nvim_buf_set_lines(viewer.body_buf, 0, -1, false, lines)
  vim.bo[viewer.body_buf].modifiable = false
  vim.bo[viewer.body_buf].filetype = filetype
  vim.wo[viewer.body_win].wrap = wrap and viewer.config.answers.wrap or false
  vim.api.nvim_win_set_cursor(viewer.body_win, { 1, 0 })
  apply_body_highlights(viewer, lines)
end

local function open_source_file(viewer)
  local path = viewer.record.context.file_path
  if not path or vim.fn.filereadable(path) ~= 1 then
    return
  end

  close_viewer(viewer)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

local function preview_file_in_split(viewer, path)
  local target = non_drawer_target_win(viewer)
  if not target then
    vim.notify("No suitable window is available for file preview", vim.log.levels.WARN, { title = "claude.nvim" })
    return false
  end

  vim.api.nvim_win_call(target, function()
    vim.cmd("belowright split " .. vim.fn.fnameescape(path))
  end)

  return true
end

local function interactive_tabs(viewer, width)
  local hl = viewer.config.answers.highlights
  local lines = { {}, {}, {} }
  local total_str_w = -1

  for _, label in ipairs(TABS) do
    total_str_w = total_str_w + vim.api.nvim_strwidth(label) + 5
  end

  for i, label in ipairs(TABS) do
    local active = tab_name(viewer) == label
    local tab_hl = active and hl.tab_active or hl.tab_inactive
    local action = function()
      switch_tab(viewer, i)
    end
    local hchar = string.rep("─", vim.api.nvim_strwidth(label) + 2)

    table.insert(lines[1], { "┌" .. hchar .. "┐", tab_hl, action })
    table.insert(lines[2], { "│ " .. label .. " │", tab_hl, action })
    table.insert(lines[3], { "└" .. hchar .. "┘", tab_hl, action })

    if i ~= #TABS then
      table.insert(lines[1], { " " })
      table.insert(lines[2], { " " })
      table.insert(lines[3], { " " })
    else
      local pad = math.max(0, width - total_str_w)
      if pad > 0 then
        table.insert(lines[1], { string.rep(" ", pad) })
        table.insert(lines[2], { string.rep(" ", pad) })
        table.insert(lines[3], { string.rep(" ", pad) })
      end
    end
  end

  return lines
end

local function footer_line(viewer)
  local hl = viewer.config.answers.highlights
  local width = viewer.spec.width - 1
  local compact = width < 72
  local file_hint = ""

  if tab_name(viewer) == "Files" then
    file_hint = compact and "  ↵ Prev" or "  <Enter> preview"
  end

  local tabs_label = compact and " Tabs 1/2/3 " or " 1 Answer  2 Question  3 Files  Tab Next "
  local copy_answer_label = compact and " y Copy " or " y Copy answer "
  local copy_comment_label = compact and " Y Cmt " or " Y Copy comment "

  return ui.hpad({
    { tabs_label, hl.footer },
    { "_pad_" },
    { " I Comment ", hl.action, function() viewer.actions.comment(viewer.record) end },
    { " " },
    { copy_answer_label, hl.action, function() viewer.actions.copy_answer(viewer.record) end },
    { " " },
    { copy_comment_label, hl.action, function() viewer.actions.copy_comment(viewer.record) end },
    { " " },
    { " o Full ", hl.action, function() close_viewer(viewer); viewer.actions.open_full(viewer.record) end },
    { file_hint ~= "" and " " or "" },
    file_hint ~= "" and { file_hint, hl.footer } or { "" },
    { " " },
    { " q Close ", hl.action, function() close_viewer(viewer) end },
  }, width)
end

local function section_lines(viewer, name)
  local hl = viewer.config.answers.highlights
  local width = viewer.spec.width - 1
  local record = viewer.record
  local source = truncate_middle(record.context.relative_path or record.context.file_label or "[No Name]", width - 10)
  local mode_hl = record.submit_mode == "comment_now" and hl.warning or hl.action
  local file_count = string.format("%d file%s", #record.consulted_files, #record.consulted_files == 1 and "" or "s")

  if name == "header" then
    local line1 = ui.hpad({
      { " 󰭹 Claude Answer", hl.title },
      { "_pad_" },
      { "󰃭 " .. record.timestamp, hl.meta },
    }, width)

    local line2 = ui.hpad({
      { " 󰈔 " .. source, hl.file, function() open_source_file(viewer) end },
      { "_pad_" },
      { "󰂻 " .. record.model, hl.meta },
      { "  ·  ", hl.meta },
      { file_count, hl.meta },
      { "  ·  ", hl.meta },
      { record.submit_mode == "comment_now" and "comment now" or "answer", mode_hl },
    }, width)

    return { line1, line2 }
  end

  if name == "tabs" then
    return interactive_tabs(viewer, width)
  end

  if name == "body_pad" then
    local lines = {}
    for _ = 1, body_geometry(viewer).height do
      lines[#lines + 1] = { { string.rep(" ", math.max(1, body_geometry(viewer).width)), hl.meta } }
    end
    return lines
  end

  return { footer_line(viewer) }
end

local function layout(buf)
  local viewer = viewers[buf]

  return {
    {
      name = "header",
      lines = function()
        return section_lines(viewer, "header")
      end,
    },
    {
      name = "tabs",
      lines = function()
        return section_lines(viewer, "tabs")
      end,
    },
    {
      name = "body_pad",
      lines = function()
        return section_lines(viewer, "body_pad")
      end,
    },
    {
      name = "footer",
      lines = function()
        return section_lines(viewer, "footer")
      end,
    },
  }
end

close_viewer = function(viewer)
  if not viewer or viewer.closing then
    return
  end

  viewer.closing = true
  viewers[viewer.shell_buf] = nil
  if current_viewer == viewer then
    current_viewer = nil
  end

  if viewer.aug then
    pcall(vim.api.nvim_del_augroup_by_id, viewer.aug)
  end

  if ok_events then
    for i = #volt_events.bufs, 1, -1 do
      if volt_events.bufs[i] == viewer.shell_buf then
        table.remove(volt_events.bufs, i)
      end
    end
  end

  for _, win in ipairs({ viewer.body_win, viewer.shell_win }) do
    if win and vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  for _, buf in ipairs({ viewer.body_buf, viewer.shell_buf }) do
    if buf and vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

local function redraw_shell(viewer)
  vim.api.nvim_set_option_value("modifiable", true, { buf = viewer.shell_buf })

  volt.gen_data({ {
    buf = viewer.shell_buf,
    ns = viewer.ns,
    layout = layout(viewer.shell_buf),
    xpad = 1,
  } })

  volt.run(viewer.shell_buf, {
    h = viewer.spec.height,
    w = viewer.spec.width,
  })
end

switch_tab = function(viewer, index)
  if not viewer then
    return
  end

  viewer.tab_index = clamp(index, 1, #TABS)
  redraw_shell(viewer)
  render_body(viewer)
end

local function cycle_tab(viewer, step)
  local next_index = viewer.tab_index + step
  if next_index > #TABS then
    next_index = 1
  elseif next_index < 1 then
    next_index = #TABS
  end

  switch_tab(viewer, next_index)
end

local function open_selected_file(viewer)
  if tab_name(viewer) ~= "Files" or not viewer.file_line_map then
    return
  end

  local row = vim.api.nvim_win_get_cursor(viewer.body_win)[1]
  local rel = viewer.file_line_map[row]
  if not rel then
    return
  end

  local path = viewer.record.context.repo_root and vim.fs.joinpath(viewer.record.context.repo_root, rel) or rel
  if vim.fn.filereadable(path) ~= 1 then
    vim.notify("Could not open consulted file: " .. rel, vim.log.levels.WARN, { title = "claude.nvim" })
    return
  end

  preview_file_in_split(viewer, path)
end

local function install_body_mappings(viewer, actions)
  local opts = { buffer = viewer.body_buf, silent = true }

  vim.keymap.set("n", "q", function()
    close_viewer(viewer)
  end, opts)

  vim.keymap.set("n", "<Esc>", function()
    close_viewer(viewer)
  end, opts)

  vim.keymap.set("n", "I", function()
    actions.comment(viewer.record)
  end, opts)

  vim.keymap.set("n", "y", function()
    actions.copy_answer(viewer.record)
  end, opts)

  vim.keymap.set("n", "Y", function()
    actions.copy_comment(viewer.record)
  end, opts)

  vim.keymap.set("n", "o", function()
    close_viewer(viewer)
    actions.open_full(viewer.record)
  end, opts)

  vim.keymap.set("n", "<Tab>", function()
    cycle_tab(viewer, 1)
  end, opts)

  vim.keymap.set("n", "<S-Tab>", function()
    cycle_tab(viewer, -1)
  end, opts)

  vim.keymap.set("n", "1", function()
    switch_tab(viewer, 1)
  end, opts)
  vim.keymap.set("n", "2", function()
    switch_tab(viewer, 2)
  end, opts)
  vim.keymap.set("n", "3", function()
    switch_tab(viewer, 3)
  end, opts)

  vim.keymap.set("n", "<CR>", function()
    open_selected_file(viewer)
  end, opts)
end

local function install_shell_mappings(viewer)
  local opts = { buffer = viewer.shell_buf, silent = true }

  vim.keymap.set("n", "q", function()
    close_viewer(viewer)
  end, opts)

  vim.keymap.set("n", "<Esc>", function()
    close_viewer(viewer)
  end, opts)

  vim.keymap.set("n", "1", function()
    switch_tab(viewer, 1)
  end, opts)
  vim.keymap.set("n", "2", function()
    switch_tab(viewer, 2)
  end, opts)
  vim.keymap.set("n", "3", function()
    switch_tab(viewer, 3)
  end, opts)

  vim.keymap.set("n", "y", function()
    viewer.actions.copy_answer(viewer.record)
  end, opts)

  vim.keymap.set("n", "Y", function()
    viewer.actions.copy_comment(viewer.record)
  end, opts)
end

local function setup_highlights(config)
  for group, link in pairs(config.highlight_links) do
    vim.api.nvim_set_hl(0, group, { link = link })
  end
end

function M.is_supported()
  return can_render()
end

function M.open_record(record, config, actions)
  if not can_render() then
    return false
  end

  if current_viewer then
    close_viewer(current_viewer)
  end

  setup_highlights(config)

  local width, height = drawer_size(config)
  local spec = drawer_position(config, width, height)
  local viewer = {
    record = record,
    config = config,
    tab_index = 1,
    spec = spec,
    ns = vim.api.nvim_create_namespace("claude_answer_drawer"),
    body_ns = vim.api.nvim_create_namespace("claude_answer_body"),
    actions = actions,
  }

  viewer.shell_buf = vim.api.nvim_create_buf(false, true)
  viewer.body_buf = vim.api.nvim_create_buf(false, true)
  viewers[viewer.shell_buf] = viewer
  current_viewer = viewer

  viewer.shell_win = vim.api.nvim_open_win(viewer.shell_buf, false, {
    relative = "editor",
    row = spec.row,
    col = spec.col,
    width = spec.width,
    height = spec.height,
    style = "minimal",
    border = config.border_style,
    focusable = true,
  })

  vim.api.nvim_set_option_value(
    "winhl",
    "Normal:NormalFloat,FloatBorder:" .. config.answers.highlights.border,
    { win = viewer.shell_win }
  )

  local body = body_geometry(viewer)
  viewer.body_win = vim.api.nvim_open_win(viewer.body_buf, true, {
    relative = "editor",
    row = body.row,
    col = body.col,
    width = body.width,
    height = body.height,
    style = "minimal",
    border = "none",
  })

  vim.api.nvim_set_option_value("winhl", "Normal:NormalFloat", { win = viewer.body_win })
  vim.bo[viewer.body_buf].buftype = "nofile"
  vim.bo[viewer.body_buf].bufhidden = "wipe"
  vim.bo[viewer.body_buf].swapfile = false
  vim.bo[viewer.body_buf].buflisted = false
  vim.bo[viewer.body_buf].modifiable = true
  vim.wo[viewer.body_win].number = false
  vim.wo[viewer.body_win].relativenumber = false
  vim.wo[viewer.body_win].signcolumn = "no"
  vim.wo[viewer.body_win].cursorline = false

  redraw_shell(viewer)
  render_body(viewer)
  if ok_events then
    volt_events.add(viewer.shell_buf)
  end
  install_shell_mappings(viewer)
  install_body_mappings(viewer, actions)

  viewer.aug = vim.api.nvim_create_augroup("ClaudeAnswerDrawer" .. viewer.shell_buf, { clear = true })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = viewer.aug,
    callback = function(args)
      local closed = tonumber(args.match)
      if closed == viewer.body_win or closed == viewer.shell_win then
        close_viewer(viewer)
      end
    end,
  })

  return true
end

return M
