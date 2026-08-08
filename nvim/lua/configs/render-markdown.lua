return {
  -- Enable rendering by default
  enabled = true,
  -- Maximum file size to render (in MB) - prevents lag on huge files
  max_file_size = 10.0,
  -- Start rendering in normal mode as well (not just visual mode)
  render_modes = { "n", "c", "v", "i" },
  -- Code block rendering
  code = {
    -- Show code blocks in the sign column
    sign = true,
    -- Width of code blocks
    width = "block",
    -- Padding around code blocks
    left_pad = 0,
    right_pad = 0,
  },
  -- Bullet list configurations
  bullet = {
    -- Icons for different nesting levels
    icons = { "●", "○", "◆", "◇" },
  },
}
