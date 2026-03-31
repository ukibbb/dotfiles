# claude.nvim

`claude.nvim` is a small floating-popup prototype for talking to Claude from
inside Neovim.

Right now it is best understood as a clean, well-commented UI shell:

- it opens a popup with an input area
- it captures visual selection context
- it lets you cycle between models
- it starts in insert mode when opened
- it can call a configurable backend CLI and open the answer in a Volt review drawer
- it can turn the last answer into inline comments in the source file with `:ClaudeComment`
- it also has an explicit comment-now mode for immediate inline comment insertion

The backend defaults to the local `claude` CLI, but the command is configurable.
That makes the plugin usable with a fake backend in tests and keeps the transport
layer separate from the UI.

## Use It

- Open the popup with `:Claude`
- Open comment-now mode with `:ClaudeCommentNow`
- Or press `<leader>ac` in normal mode
- Or select text in visual mode and press `<leader>ac`
- Or press `<leader>aC` to ask Claude and insert comments immediately on success
- Type your prompt
- Press `<Tab>` to cycle models
- Press `<F2>` to toggle between answer mode and comment-now mode inside the popup
- Press `<Enter>` to submit the prompt to the backend
- Press `<C-j>` to insert a newline in the prompt
- Press `<Esc>` or `q` to close
- Press `<C-c>` to cancel an in-flight request
- Press `<C-l>` to clear the input buffer

After a successful answer:

 - in normal answer mode, a right-side review drawer opens with the answer, question, and consulted files
 - press `I` there or run `:ClaudeComment` to insert the last answer into the
   source file as comments
 - if `watchdiff.nvim` is active, the resulting file change is annotated as coming
   from `claude.nvim`, and you can inspect provenance with `:WatchDiffHistory`
 - press `o` in the drawer to open the full legacy scratch buffer

In comment-now mode:

- Claude still stores the answer record internally
- if the comment insertion is safe, comments are written to the source file immediately
- if insertion is unsafe, the plugin falls back to the same review drawer

The popup is designed to land directly in insert mode after it opens.

Mode cues in the popup:

- answer mode shows an `[answer]` badge in the header
- comment-now mode shows a `[comment now]` badge and uses the comment highlight on the border and submit hint
- the footer now shows `F2` as the in-popup mode switch

Answer view cues:

- the default answer UI is a right-side Volt drawer
- use `1`, `2`, `3` or `<Tab>` / `<S-Tab>` to switch `Answer`, `Question`, and `Files`
- press `<Enter>` on the `Files` tab to preview a consulted file in a split while keeping the drawer open
- press `y` to copy the answer text and `Y` to copy the comment-ready block
- press `o` to open the full legacy scratch buffer
- the tabs and footer actions are also clickable with the mouse
- the header now shows compact metadata with icons, and the `Files` tab is styled as a review list

## Learn It

If you want to understand the plugin from top to bottom, read the files in this
order:

1. `lua/claude/init.lua`
2. `lua/claude/controller.lua`
3. `lua/claude/render.lua`
4. `lua/claude/input.lua`
5. `lua/claude/backend.lua`
6. `lua/claude/request.lua`
7. `lua/claude/output.lua`
8. `lua/claude/output_drawer.lua`
9. `lua/claude/output_scratch.lua`
10. `lua/claude/comments.lua`
11. `lua/claude/writer.lua`
12. `lua/claude/layout.lua`
13. `lua/claude/context.lua`
14. `lua/claude/state.lua`
15. `lua/claude/dev.lua`

There is also a full prose walkthrough in `ARCHITECTURE.md`.

## Module Map

- `lua/claude/init.lua` - public API and setup
- `lua/claude/controller.lua` - popup lifecycle orchestration
- `lua/claude/render.lua` - windows, buffers, redraw, cleanup
- `lua/claude/input.lua` - input keymaps, placeholder, insert mode
- `lua/claude/backend.lua` - async backend process execution
- `lua/claude/request.lua` - structured prompt and response schema
 - `lua/claude/output.lua` - answer-viewer facade and fallback selection
 - `lua/claude/output_drawer.lua` - Volt-based review drawer UI
 - `lua/claude/output_scratch.lua` - legacy full scratch answer buffer
- `lua/claude/comments.lua` - safe answer-to-comment conversion
- `lua/claude/writer.lua` - on-disk writes for watchdiff-friendly edits
- `lua/claude/layout.lua` - geometry and text construction
- `lua/claude/context.lua` - visual selection and file context capture
- `lua/claude/state.lua` - current popup session state
- `lua/claude/config.lua` - defaults and config merging
- `lua/claude/dev.lua` - hot reload helpers for development

## Development Workflow

When editing this plugin from your Neovim config, your `autocmds.lua` already
loads `claude.dev` automatically.

That gives you:

- `<leader>rr` - reload all `claude.*` modules
- `<leader>rt` - reload and immediately open the popup
- `<leader>rd` - show which `claude.*` modules are currently loaded

## Watchdiff Gate

Before relying on file-comment insertion as a review workflow, validate
`watchdiff.nvim` with the checklist in `../watchdiff.nvim/VALIDATION.md`.
