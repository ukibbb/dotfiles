# watchdiff.nvim Validation Checklist

This checklist is the gate we should pass before we build any feature that
depends on `watchdiff.nvim` for visibility.

The goal is to prove that `watchdiff.nvim` reliably shows file changes made on
disk by external tools, especially the future `claude.nvim` comment-writer flow.

## What We Need To Prove

- the plugin loads cleanly on its own
- it detects add/change/delete edits made outside Neovim
- highlights accumulate until cleared
- unsaved user edits stay protected
- comment blocks written to disk are surfaced clearly enough to review

## Test Environment

Use a throwaway directory, not a real project file.

```bash
mkdir -p /tmp/watchdiff-validation
cd /tmp/watchdiff-validation
git init
printf 'alpha\nbeta\ngamma\n' > test.lua
```

Then open Neovim with only `watchdiff.nvim` on `runtimepath`:

```bash
nvim -u NONE \
  "+set rtp+=/Users/lukasz/Desktop/dotfiles/watchdiff.nvim" \
  "+lua require('watchdiff').setup({})" \
  test.lua
```

## Stage 1: Standalone Load Proof

Expected result:

- Neovim starts without errors
- `test.lua` opens normally
- `<leader>ch` is mapped
- there are no watcher startup errors in `:messages`

## Stage 2: Add / Change / Delete Detection

With `test.lua` still open in Neovim, edit it from another terminal.

### Add lines

```bash
printf 'alpha\nbeta\ngamma\ndelta\n' > /tmp/watchdiff-validation/test.lua
```

Expected result:

- buffer reloads automatically
- added line highlights green
- notification appears

### Change lines

```bash
printf 'alpha\nBETA\ngamma\ndelta\n' > /tmp/watchdiff-validation/test.lua
```

Expected result:

- changed line highlights green
- previous highlights still remain if not cleared

### Delete lines

```bash
printf 'alpha\nBETA\ndelta\n' > /tmp/watchdiff-validation/test.lua
```

Expected result:

- deleted line appears as red virtual text
- the placement is visually understandable in the window

## Stage 3: Accumulation And Clear Baseline

Without pressing `<leader>ch`, make another external edit.

```bash
printf 'alpha\nBETA\ndelta\nepsilon\n' > /tmp/watchdiff-validation/test.lua
```

Expected result:

- highlights represent all changes since the original acknowledged baseline

Then press `<leader>ch` inside Neovim.

Expected result:

- highlights disappear
- a notification confirms the clear

Now make one more external edit:

```bash
printf 'alpha\nBETA\ndelta\nEPSILON\n' > /tmp/watchdiff-validation/test.lua
```

Expected result:

- only the new change is highlighted
- old cleared changes do not come back

## Stage 4: Unsaved Edit Protection

Inside Neovim, make a local unsaved edit to `test.lua`.

Then from another terminal:

```bash
printf 'alpha\nchanged outside\ndelta\nEPSILON\n' > /tmp/watchdiff-validation/test.lua
```

Expected result:

- Neovim does not silently reload the buffer
- your unsaved edit is preserved
- a warning explains the conflict

This is a hard safety requirement. If this fails, do not build Claude comment
insertion on top of watchdiff yet.

## Stage 5: Split Window Rendering

Open the same file in a split and repeat one delete test.

Expected result:

- deleted virtual lines still render sensibly
- full-width highlights are not obviously broken in the visible split

## Stage 6: Simulated Claude Comment Insertion

Reset the file first:

```bash
printf 'local value = 42\nreturn value\n' > /tmp/watchdiff-validation/test.lua
```

With the file open in Neovim, simulate the future Claude workflow by inserting a
comment block from another terminal:

```bash
printf 'local value = 42\n-- Claude: This module returns a fixed sentinel value.\n-- Claude: It is useful as a tiny example for watchdiff validation.\nreturn value\n' > /tmp/watchdiff-validation/test.lua
```

Expected result:

- the comment block is detected as an external change
- the buffer reloads cleanly
- the new comment lines are highlighted clearly enough to review

This is the key go/no-go test for `claude.nvim` integration.

## Go / No-Go Decision

## Go

Proceed with `claude.nvim` integration if all of these pass:

- standalone load works
- add/change/delete detection works
- accumulation and clear work
- unsaved edits are protected
- simulated comment insertion is clearly surfaced

## No-Go

Do not depend on `watchdiff.nvim` yet if any of these happen:

- external edits are not reliably detected
- the wrong file reloads or fails to reload
- unsaved edits are clobbered
- inserted comments are too hard to review visually

## Notes To Record During Validation

For each test, write down:

- whether reload happened
- whether the highlight matched the true change
- whether notifications were helpful
- whether any flicker, duplicate events, or missed edits occurred
- whether the result feels trustworthy enough for Claude-made file comments
