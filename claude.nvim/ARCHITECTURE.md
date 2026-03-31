# claude.nvim Architecture

This document explains how the whole plugin works after the refactor.

The goal of the refactor was simple:

- each module should have one clear job
- each function should have a single reason to exist
- the code should teach you how it works while you read it

## Big Picture

The plugin is a floating popup with two layers:

1. a shell window that draws the header and footer
2. a real input window on top of the shell's empty middle section

That split is the key UI idea in the plugin.

The shell window is not meant for editing. It only provides visual chrome:

- close icon
- model label
- tab hint
- enter/send hint

The input window is the real editable buffer where the user types.

## Runtime Flow

When you press `<leader>ac` or run `:Claude`, the flow looks like this:

```text
setup()
  -> open()
    -> controller.open(config)
      -> context.capture_visual_selection()
      -> state.new(context)
      -> render.setup_highlights(config)
      -> render.create(session, config)
        -> layout.main_window_spec(config, context)
        -> layout.input_window_spec(config, main_spec)
        -> render.redraw(session, config)
          -> layout.build_chrome(config, current_model)
      -> input.attach(session, config, actions)
      -> input.enter_insert_mode(session)
```

On submit, the flow is now:

```text
<Enter>
  -> input buffer keymap
    -> controller.submit(config)
      -> input.get_text(session)
      -> backend.start(...)
        -> request.build_prompt(...)
      -> backend returns structured answer JSON
      -> state.set_last_record(record)
      -> controller.close()
      -> if submit_mode == answer
           -> output.open_record(record)
         else if submit_mode == comment_now
           -> comments.insert(record)
           -> fallback to output.open_record(record) if insertion is unsafe
```

## Module Responsibilities

## `lua/claude/init.lua`

This is the public entry point.

It owns:

- `setup()`
- public `open()` / `close()` helpers
- global keymaps
- the `:Claude` command
- the active merged config

It does not know how to build windows, capture selections, or manage input.

That is important. `init.lua` should read like the front door of the plugin,
not like the whole implementation.

## `lua/claude/controller.lua`

This is the orchestrator.

It decides the order of operations when the popup opens or closes.

It is responsible for:

- toggling the popup
- capturing selection context before visual mode is lost
- creating a new runtime session
- telling render/input what to do
- deciding what submit means

This file is where the plugin's behavior lives.

If you later add a real Claude API call, this is the first place to extend.

It also owns the new "answer now, comment later" flow by storing the most recent
successful answer as a reusable record.

It now also owns the explicit `comment_now` flow, where the same answer record is
generated first and then immediately applied to the file if the safety checks pass.

## `lua/claude/render.lua`

This module owns Neovim side effects related to drawing:

- creating buffers
- creating floating windows
- writing the shell text
- applying highlight spans
- tearing everything down on close

It does not decide *when* the popup opens. It only knows *how* to show or hide
it once asked.

## `lua/claude/input.lua`

This module owns behavior attached to the input buffer:

- submit keymaps
- close keymaps
- clear keymap
- model-cycling keymaps
- placeholder overlay
- insert-mode handoff

This module does not decide what submit or close actually do. Those actions are
injected by `controller.lua`.

That is a major separation-of-concerns improvement in the refactor.

Before the refactor, behavior was split between the old `init.lua` and `gui.lua`.
Now all input-buffer behavior lives in one place.

It also now distinguishes between:

- submit
- cancel in-flight request
- newline insertion with `<C-j>`
- in-popup mode switching with `<F2>`

so the prompt can still be multiline even though `<Enter>` submits.

## `lua/claude/backend.lua`

This module runs the external backend command asynchronously.

By default that backend is the local `claude` CLI, but the module is explicitly
configurable so tests can inject a fake command that prints canned JSON.

That keeps the transport concerns isolated from the rest of the plugin.

## `lua/claude/request.lua`

This module builds the prompt text and the JSON schema expected back from the
backend.

It is the layer that tells Claude:

- start from the selected code or current file
- inspect more files only if needed
- answer in a structured way
- provide a short comment-ready variant if possible

## `lua/claude/output.lua`

Successful answers are rendered through an output facade.

By default it opens a right-side Volt drawer for review. That drawer is designed
to feel like a code-review companion rather than a raw markdown dump.

It also gives the user an explicit place to review the answer before deciding to
insert it into source comments.

When `comment_now` is requested, the same drawer becomes the fallback path if
automatic comment insertion is rejected as unsafe.

## `lua/claude/output_drawer.lua`

This module owns the richer review drawer.

It uses Volt for the frame and a normal read-only body buffer for the tabbed
content. That split gives the plugin polished chrome and actions without giving
up the benefits of reading long text in a normal buffer.

The drawer uses Volt clickables for:

- tab switching
- footer actions
- opening the source file from the header metadata row

The `Files` tab now previews consulted files in a split instead of replacing the
current review context, and the footer also exposes copy actions for the raw
answer text and the comment-ready variant.

The default tabs are:

- `Answer`
- `Question`
- `Files`

## `lua/claude/output_scratch.lua`

This module preserves the original full scratch answer buffer.

It remains useful as:

- a fallback when Volt is unavailable
- the `o` action from the drawer when the user wants the full plain buffer

## `lua/claude/comments.lua`

This module turns a stored answer into safe inline comments.

It decides whether the answer is still anchored safely enough to the source file,
sanitizes the answer into short comment lines, and applies `commentstring`.

If the file changed since the answer was generated, it refuses to insert comments.

## `lua/claude/writer.lua`

This module performs the actual on-disk write for inserted comments.

That is an intentional design choice: writing to disk instead of mutating the
buffer directly allows `watchdiff.nvim` to detect and highlight the change as an
external edit.

## `lua/claude/layout.lua`

This module answers the question:

"What should the popup look like right now?"

It calculates:

- popup position
- popup dimensions
- shell text
- placeholder text
- highlight spans for semantic UI parts

The popup header and footer now also make submit mode obvious, with an explicit
badge like `[answer]` or `[comment now]` and mode-colored submit text.

The important design choice here is that `layout.lua` returns data, not windows.

That means `render.lua` can focus on Neovim API calls while `layout.lua` focuses
on geometry and strings.

## `lua/claude/context.lua`

This module captures editor context before the popup opens.

That is mainly:

- whether the user is in visual mode
- the selected text
- selection coordinates
- current file label

This logic is isolated because visual selections are fragile. Once Neovim leaves
visual mode or moves focus, some selection information is no longer easy to read.

Capturing it early and converting it to plain Lua data makes the rest of the
plugin much simpler.

## `lua/claude/state.lua`

This module stores the current popup session.

The plugin only supports one popup at a time, so the state model stays simple:

- one current session
- that session holds runtime data only

Runtime data includes:

- `context`
- `handles`
- `model_index`
- per-session namespaces

Config does not live here because config is stable input, not live session state.

## `lua/claude/config.lua`

This module owns defaults and config merging.

It gives the rest of the plugin a single source of truth for:

- dimensions
- icons
- models
- highlight groups
- placeholder text

Keeping this in one file prevents visual constants from leaking into unrelated
modules.

## `lua/claude/dev.lua`

This is a development-only helper module.

It clears cached `claude.*` modules from `package.loaded`, re-runs setup, and
offers convenience keymaps while you work on the plugin.

It is intentionally separate from the main runtime path so plugin behavior and
developer tooling stay decoupled.

## Why the Plugin Uses Two Windows

The popup is easier to build and reason about with two windows instead of one.

If the input buffer also contained the header and footer text, then editing would
become awkward:

- the user could move into the decorative lines
- placeholder logic would get more complicated
- redraws would risk touching editable content

By splitting the popup into:

- one shell window for chrome
- one input window for typing

the responsibilities become very clean.

## Why Insert Mode Is Scheduled

One subtle Neovim behavior is that leaving visual mode and opening floats can
both enqueue editor state changes.

If the plugin calls `startinsert` too early, Neovim can still end up in normal
mode afterward.

That is why `input.enter_insert_mode()` uses `vim.schedule()`:

- finish creating windows first
- let visual-mode exit settle if needed
- then focus the input window
- then enter insert mode

This is the reason the popup now opens much more reliably in insert mode.

## Why Answers Open In A Scratch Buffer

The popup is a focused composer, not a full conversation UI.

Once an answer arrives, the plugin closes the popup and opens a scratch answer
buffer instead.

That keeps the input flow simple while still giving the user a place to:

- read the answer
- see consulted files
- decide whether to insert the answer into source comments

This also makes the "answer first, comment later" workflow explicit and safe.

## Best Reading Order In The Code

If you want to learn the codebase in the same order it runs, read:

1. `lua/claude/init.lua`
2. `lua/claude/controller.lua`
3. `lua/claude/render.lua`
4. `lua/claude/input.lua`
5. `lua/claude/backend.lua`
6. `lua/claude/request.lua`
7. `lua/claude/output.lua`
8. `lua/claude/comments.lua`
9. `lua/claude/writer.lua`
10. `lua/claude/layout.lua`
11. `lua/claude/context.lua`
12. `lua/claude/state.lua`
13. `lua/claude/config.lua`
14. `lua/claude/dev.lua`

## Watchdiff Integration Point

If you choose to insert answers as comments, `writer.lua` writes the change to
disk instead of mutating the source buffer directly.

That is the seam where `watchdiff.nvim` can validate and eventually surface
Claude-made comment insertions as reviewable file changes.

The current integration also annotates those writes as `claude.nvim` changes, so
`watchdiff.nvim` history can show when Claude inserted comments and which prompt
that comment write came from.
