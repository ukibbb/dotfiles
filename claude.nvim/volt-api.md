# Volt API Reference

Source: https://github.com/nvzone/volt

## Overview

Volt is a Neovim plugin for creating interactive UIs with reactive rendering using extmarks.

## Core Functions

```lua
local volt = require("volt")
```

### volt.gen_data(data)

Initialize state for buffers with layout info.

```lua
volt.gen_data({
  {
    buf = buf,             -- buffer handle
    ns = ns,               -- namespace for extmarks
    layout = layout(buf),  -- layout TABLE (call your layout function, not the function itself!)
    xpad = 0,              -- optional horizontal padding
  }
})
```

**IMPORTANT:** The `layout` field must be the result of calling your layout function (a table of sections), NOT the function itself.

### volt.run(buf, opts)

Render content, set filetype to "VoltWindow", enable mouse events and keyboard navigation.

```lua
volt.run(buf, {
  h = height,                    -- required: buffer height
  w = width,                     -- required: buffer width
  custom_empty_lines = fn,       -- optional: custom line init function
})
```

After calling `volt.run`, the following keymaps are automatically set on the buffer:
- `Tab` / `Shift-Tab` - cycle through clickable elements
- `Enter` - activate the element under cursor
- `CursorMoved` - triggers slider interactions

### volt.set_empty_lines(buf, n, w)

Initialize buffer with empty lines (called automatically by volt.run unless custom_empty_lines is provided).

```lua
volt.set_empty_lines(buf, 10, 40)  -- 10 lines, 40 chars wide
```

### volt.redraw(buf, names)

Re-render specific sections or all.

```lua
volt.redraw(buf, "all")              -- redraw everything
volt.redraw(buf, "section_name")     -- redraw one section
volt.redraw(buf, {"sec1", "sec2"})   -- redraw multiple sections
```

### volt.mappings(val)

Setup keymaps for closing and cycling buffers.

```lua
volt.mappings({
  bufs = { buf1, buf2 },         -- buffers to apply mappings
  winclosed_event = true,        -- optional: handle WinClosed autocmd
  close_func = function(buf),    -- optional: called when closing each buffer
  after_close = function(),      -- optional: called after all buffers closed
})
```

Sets up:
- `q` and `ESC` to close
- `Ctrl-T` to cycle between buffers (if multiple)

### volt.close(buf)

Close a volt popup window.

```lua
volt.close()      -- close current (sends 'q' keypress)
volt.close(buf)   -- close specific buffer
```

### volt.toggle_func(open_func, ui_state)

Toggle popup open/close.

```lua
volt.toggle_func(M.open_popup, some_state_boolean)
```

## Layout Structure

Layout function returns an array of sections:

```lua
local function layout(buf)
  return {
    {
      name = "header",
      lines = function(buf)
        return {
          -- line 1
          {
            { "Hello ", "Normal" },
            { "World", "String" },
          },
          -- line 2
          {
            { "Click me", "Keyword", function() print("clicked!") end },
          },
        }
      end,
    },
    {
      name = "content",
      col_start = 2,  -- optional: column offset for this section
      lines = function(buf)
        return { ... }
      end,
    },
  }
end
```

### Mark Format

Each mark in a line: `{ text, highlight, actions }`

- `text` - string to display
- `highlight` - highlight group name (e.g., "Normal", "String", "Keyword")
- `actions` - optional, can be:
  - Function: `function() ... end`
  - Vim command string: `"echo 'hello'"`
  - Table with click/hover:
    ```lua
    {
      click = function() ... end,
      hover = {
        id = "unique_id",
        redraw = "section_name",  -- section to redraw on hover
        callback = function() ... end,
      },
      ui_type = "slider",  -- for special UI components
    }
    ```

## UI Components

```lua
local ui = require("volt.ui")
```

### ui.checkbox(opts)

```lua
ui.checkbox({
  active = true,              -- checked state
  txt = "Enable feature",     -- label text
  check = "",               -- optional: custom check icon (default: )
  uncheck = "",             -- optional: custom uncheck icon (default: )
  hlon = "String",            -- optional: highlight when active (default: "String")
  hloff = "ExInactive",       -- optional: highlight when inactive (default: "ExInactive")
  actions = { click = fn },   -- optional: click handler
})
-- Returns: { " Enable feature", "String", actions }  (single mark, not a line)
```

### ui.progressbar(opts)

```lua
ui.progressbar({
  w = 20,                     -- total width
  val = 75,                   -- progress 0-100
  icon = { on = "-", off = "-" },     -- optional (default: "-")
  hl = { on = "exred", off = "linenr" },  -- optional
})
-- Returns: { { "---------------", hl }, { "-----", hl } }  (two marks)
```

### ui.slider.config(opts)

Interactive slider with mouse/keyboard support. Returns a single line (array of marks).

```lua
local slider = require("volt.ui").slider

slider.config({
  w = 30,                     -- total width
  val = 50,                   -- current value 0-100
  txt = "Volume: ",           -- optional: left label
  hlon = "String",            -- active part highlight
  hloff = "LineNr",           -- inactive part highlight (default: "LineNr")
  thumb = true,               -- show thumb indicator
  thumb_icon = "",           -- optional: custom thumb (default: )
  ratio_txt = true,           -- show percentage text (uses "Commentfg" hl)
  actions = function()        -- called on interaction
    -- use slider.val() to get new value
  end,
})
-- Returns a line (array of marks), not wrapped in another array
```

### slider.val(w, left_txt, xpad, opts)

Get slider value from cursor position (used in actions callback).

```lua
local new_val = slider.val(width, "Volume: ", xpad, {
  thumb = true,   -- whether thumb is enabled
  ratio = true,   -- whether ratio_txt is enabled (adjusts width calculation)
})
```

### ui.separator(char, w, hl)

```lua
ui.separator("─", 40, "linenr")  -- default hl is "linenr"
-- Returns: { { "────────────...", "linenr" } }  (a line with one mark)
```

### ui.table(tbl, w, header_hl, title)

Create a bordered table with centered content.

```lua
ui.table(
  {
    { "Name", "Age", "City" },           -- header row
    { "Alice", "25", "NYC" },            -- data rows...
    { "Bob", "30", "LA" },
  },
  80,                                    -- total width (or "fit" to auto-size)
  "exgreen",                             -- header highlight (default: "exgreen")
  { "Table Title", "Normal" }            -- optional title (mark format)
)
-- Returns lines array with borders (┌─┬─┐, │ │, ├─┼─┤, └─┴─┘)
```

### ui.tabs(data, w, opts)

Tabbed interface with borders.

```lua
ui.tabs(
  { "Tab1", "_pad_", "Tab2", "Tab3" },  -- "_pad_" adds flexible space
  80,                                    -- total width
  {
    active = "Tab1",     -- currently active tab
    hlon = "normal",     -- active highlight (default: "normal")
    hloff = "commentfg", -- inactive highlight (default: "commentfg")
  }
)
-- Returns 3 lines (top border, content, bottom border)
```

### ui.border(lines, hl)

Wrap lines with a box border (modifies in place).

```lua
local lines = {
  { { "Line 1", "Normal" } },
  { { "Line 2", "Normal" } },
}
ui.border(lines, "linenr")  -- default hl is "linenr"
-- lines is now wrapped with ┌─┐ │ │ └─┘
```

### ui.grid_row(tb)

Combine multiple line arrays into one (vertical stacking).

```lua
ui.grid_row({ lines1, lines2, lines3 })
```

### ui.grid_col(columns)

Horizontal layout of multiple columns.

```lua
ui.grid_col({
  { lines = lines1, w = 20, pad = 2 },  -- pad is optional spacing
  { lines = lines2, w = 30 },
})
-- Returns lines with columns side by side
```

### ui.hpad(line, w)

Add horizontal padding. Use `"_pad_"` as placeholder.

```lua
local line = { { "Left", "Normal" }, { "_pad_" }, { "Right", "Normal" } }
ui.hpad(line, 40)  -- "_pad_" becomes spaces to fill width
```

### ui.line_w(line)

Calculate display width of a line.

```lua
local width = ui.line_w(line)
```

## Graphs

```lua
local graphs = require("volt.ui").graphs
```

### graphs.bar(data)

Vertical bar graph (10 rows height).

```lua
graphs.bar({
  val = { 30, 50, 80, 20, 90 },  -- values 0-100
  baropts = {
    w = 2,                       -- bar width
    gap = 1,                     -- gap between bars
    icon = "█",                  -- bar character
    hl = "exgreen",              -- bar highlight
    -- OR for dual colors:
    dual_hl = { "Comment", "String" },  -- { inactive, active }
    -- OR for dynamic colors:
    format_hl = function(val) return val > 50 and "String" or "Comment" end,
  },
  format_labels = function(i) return tostring(i * 10) .. "%" end,  -- side labels
  footer_label = { "Mon", "Tue", "Wed", "Thu", "Fri" },            -- bottom labels
})
```

### graphs.dot(data)

Dot graph (10 rows height).

```lua
graphs.dot({
  val = { 30, 50, 80, 20, 90 },
  baropts = {
    icons = { on = " 󰄰", off = " ·" },    -- default icons
    hl = { on = "exblue", off = "commentfg" },
    sidelabels = true,                    -- show side labels (default: true)
    format_icon = function(val) ... end,  -- dynamic icon
    format_hl = function(val) ... end,    -- dynamic highlight
  },
  format_labels = function(i) return tostring(i * 10) end,
  footer_label = { "A", "B", "C", "D", "E" },
})
```

## Events

Events are automatically enabled when `volt.run` is called. You can also manually manage event buffers:

```lua
local events = require("volt.events")

events.add(buf)        -- add buffer to event handling
events.add({buf1, buf2})  -- add multiple buffers
events.enable()        -- enable global mouse/key handling (called automatically)
```

## State

```lua
local state = require("volt.state")
state[buf].clickables  -- click targets by row: { [row] = { {col_start, col_end, actions}, ... } }
state[buf].hoverables  -- hover targets by row
state[buf].layout      -- layout table (sections array)
state[buf].ns          -- namespace
state[buf].h           -- calculated height
state[buf].xpad        -- horizontal padding
```

## Example: Complete Plugin

```lua
local M = {}
local volt = require("volt")
local ui = require("volt.ui")

M.config = { volume = 50, enabled = false }

local function layout(buf)
  return {
    {
      name = "header",
      lines = function(buf)
        return {
          { { "  Settings", "Title" } },
          ui.separator("─", 38),
        }
      end,
    },
    {
      name = "controls",
      lines = function(buf)
        return {
          { ui.checkbox({
              active = M.config.enabled,
              txt = "Enable feature",
              actions = { click = function()
                M.config.enabled = not M.config.enabled
                volt.redraw(buf, "controls")
              end }
            })
          },
          ui.slider.config({
            w = 38,
            val = M.config.volume,
            txt = "Vol: ",
            hlon = "String",
            ratio_txt = true,
            thumb = true,
            actions = function()
              M.config.volume = ui.slider.val(38, "Vol: ", 0, { thumb = true })
              volt.redraw(buf, "controls")
            end,
          }),
        }
      end,
    },
  }
end

function M.open()
  local buf = vim.api.nvim_create_buf(false, true)
  local ns = vim.api.nvim_create_namespace("myplugin")
  local w, h = 40, 6

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w, height = h,
    col = (vim.o.columns - w) / 2,
    row = (vim.o.lines - h) / 2,
    style = "minimal",
    border = "rounded",
  })

  volt.gen_data({ { buf = buf, ns = ns, layout = layout(buf) } })
  volt.run(buf, { h = h, w = w })
  volt.mappings({ bufs = { buf } })
end

return M
```
