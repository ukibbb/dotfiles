# Bash Scripting Guide

A living document explaining Bash concepts as they're used in this project.

---

## Table of Contents

1. [Shebang Line](#shebang-line)
2. [Script Options (set)](#script-options-set)
3. [Variables](#variables)
4. [Parameter Expansion](#parameter-expansion)
5. [Functions](#functions)
6. [Dependency Checking](#dependency-checking)
7. [Short-Circuit Operators](#short-circuit-operators)
8. [Command Grouping](#command-grouping)
9. [String Concatenation](#string-concatenation)
10. [Command Substitution](#command-substitution)
11. [Conditionals](#conditionals)
12. [Pipelines](#pipelines)
13. [Redirections](#redirections)
14. [The fd Command](#the-fd-command)

---

## Shebang Line

```bash
#!/usr/bin/env bash
```

**What:** The first line of a script that tells the system which interpreter to use.

**Why:** Without it, the system doesn't know how to execute the file. Using `env bash` instead of `/bin/bash` finds bash wherever it's installed (more portable across systems).

**Syntax:**
- `#!` - The "shebang" or "hashbang" characters
- `/usr/bin/env` - A program that finds executables in your PATH
- `bash` - The interpreter we want

---

## Script Options (set)

```bash
set -euo pipefail
```

**What:** Configures how the shell behaves during script execution.

**Why:** Makes scripts fail loudly instead of silently continuing with errors.

**Breakdown:**

| Option | Meaning | Without It |
|--------|---------|------------|
| `-e` | Exit immediately if any command fails (non-zero exit code) | Script continues even after errors |
| `-u` | Treat unset variables as errors | Unset variables silently become empty strings |
| `-o pipefail` | Pipeline fails if ANY command in it fails | Pipeline only fails if the LAST command fails |

**Example of why `-o pipefail` matters:**

```bash
# Without pipefail:
false | true    # Exit code: 0 (only checks 'true')

# With pipefail:
false | true    # Exit code: 1 (checks all commands)
```

---

## Variables

```bash
START_DIR="${1:-$HOME}"
FZF_COLORS="--color=bg:#000000"
```

**What:** Named containers that store values.

**Why:** Reuse values, make scripts configurable, store command output.

**Syntax Rules:**
- No spaces around `=` when assigning: `VAR="value"` ✓ / `VAR = "value"` ✗
- Use `$VAR` or `${VAR}` to access the value
- Quote variables to handle spaces: `"$VAR"` not `$VAR`
- Convention: UPPERCASE for constants, lowercase for local variables

**Special Variables:**

| Variable | Meaning |
|----------|---------|
| `$0` | Script name |
| `$1`, `$2`, etc. | Positional arguments passed to script |
| `$@` | All arguments as separate words |
| `$#` | Number of arguments |
| `$?` | Exit code of last command |
| `$$` | Process ID of current script |
| `$HOME` | User's home directory |

---

## Parameter Expansion

```bash
START_DIR="${1:-$HOME}"
```

**What:** Advanced ways to manipulate variables when accessing them.

**Why:** Provide defaults, modify strings, handle missing values - all in one expression.

**Common Patterns:**

| Syntax | Meaning | Example |
|--------|---------|---------|
| `${VAR:-default}` | Use `default` if VAR is unset or empty | `${1:-$HOME}` → use home if no arg |
| `${VAR:=default}` | Set VAR to `default` if unset, then use it | Assigns AND returns |
| `${VAR:?error}` | Exit with `error` message if VAR is unset | `${1:?Missing arg}` |
| `${VAR:+value}` | Use `value` if VAR IS set | Opposite of `:-` |

**In our script:**
```bash
START_DIR="${1:-$HOME}"
# If $1 (first argument) is provided, use it
# Otherwise, use $HOME (user's home directory)
```

---

## Functions

```bash
list_directories() {
    local dir="$1"
    fd --type d --hidden . "$dir"
}
```

**What:** Reusable blocks of code that can be called by name.

**Why:** Organize code, avoid repetition, make scripts more readable.

**Syntax:**
```bash
function_name() {
    # commands
}

# Call the function
function_name arg1 arg2
```

**Inside functions:**
- `$1`, `$2`, etc. are the arguments passed to the function (not the script!)
- `$@` is all arguments
- `$#` is the number of arguments

**The `local` keyword:**
```bash
my_function() {
    local name="$1"      # Only visible inside this function
    GLOBAL_VAR="hello"   # Visible everywhere (no 'local')
}
```

**Why use `local`:** Prevents variables from leaking out and accidentally overwriting other variables. Always use `local` for function variables.

**Return values:**
- Functions return exit codes (0-255) via `return`
- To return data, use stdout: `echo "$result"`
- Capture with command substitution: `result=$(my_function)`

**Example:**
```bash
greet() {
    local name="$1"
    echo "Hello, $name!"
}

# Call it
greet "World"           # Prints: Hello, World!
message=$(greet "Bob")  # Captures: Hello, Bob!
```

---

## Dependency Checking

```bash
command -v fd &>/dev/null || {
    echo "Error: 'fd' is not installed." >&2
    exit 1
}
```

**What:** Verify that required programs are installed before running the script.

**Why:** Give clear error messages instead of cryptic "command not found" errors.

**The `command -v` builtin:**
```bash
command -v <program>
```
- Returns the path to `<program>` if it exists
- Returns nothing and exit code 1 if not found
- Preferred over `which` (more portable)

**Examples:**
```bash
# Check if git is installed
if command -v git &>/dev/null; then
    echo "Git is installed"
else
    echo "Git is NOT installed"
fi

# One-liner with ||
command -v git &>/dev/null || echo "Git not found"
```

---

## Short-Circuit Operators

```bash
command -v fd &>/dev/null || exit 1
[[ -n "$selected" ]] && echo "$selected"
```

**What:** `||` (OR) and `&&` (AND) operators that conditionally run commands.

**Why:** Write concise conditional logic without full if/then/fi blocks.

**How they work:**

| Operator | Meaning | Runs right side when... |
|----------|---------|------------------------|
| `A \|\| B` | OR | A fails (exit code ≠ 0) |
| `A && B` | AND | A succeeds (exit code = 0) |

**Think of it as:**
- `||` = "or else" / "if that fails, do this"
- `&&` = "and then" / "if that succeeds, do this"

**Examples:**
```bash
# Run backup, or print error if it fails
./backup.sh || echo "Backup failed!"

# Only delete if file exists
[[ -f "$file" ]] && rm "$file"

# Chain multiple commands
mkdir -p "$dir" && cd "$dir" && touch file.txt

# Exit if command fails
command -v fd &>/dev/null || exit 1
```

**Combined with `|| true`:**
```bash
# Ignore errors from a command
risky_command || true   # Script continues even if it fails
```

---

## Command Grouping

```bash
command -v fd &>/dev/null || {
    echo "Error: 'fd' is not installed." >&2
    echo "Install with: brew install fd" >&2
    exit 1
}
```

**What:** Run multiple commands as a single unit using `{ ... }`.

**Why:** Execute multiple commands after `||` or `&&`, or redirect output of multiple commands together.

**Syntax:**
```bash
{ command1; command2; command3; }
```
**Important:** Space after `{`, semicolon before `}`, or newlines between commands.

**Difference from `( ... )`:**
- `{ ... }` runs in current shell (can modify variables, exit script)
- `( ... )` runs in subshell (isolated, can't affect parent)

**Examples:**
```bash
# Multiple commands after ||
test -f config.json || {
    echo "Config not found"
    echo "Creating default config..."
    echo '{}' > config.json
}

# Redirect output of multiple commands
{
    echo "Header"
    cat data.txt
    echo "Footer"
} > output.txt

# Exit script if dependency missing (wouldn't work with subshell)
command -v node &>/dev/null || {
    echo "Node.js required" >&2
    exit 1   # Exits the whole script, not just the group
}
```

**Redirecting to stderr with `>&2`:**
```bash
echo "This is an error message" >&2
```
- `>&2` redirects stdout to stderr
- Error messages should go to stderr, not stdout
- Allows users to separate errors from normal output

---

## String Concatenation

```bash
FZF_COLORS="--color=bg:#000000,fg:#e0e0e0"
FZF_COLORS+=",info:#50fa7b,prompt:#00d9ff"
```

**What:** Building strings by joining pieces together.

**Why:** Create complex strings incrementally, improve readability.

**Syntax:**
- `+=` appends to existing variable
- Strings next to each other automatically concatenate: `"hello""world"` → `"helloworld"`

**Example:**
```bash
MSG="Hello"
MSG+=", World"    # MSG is now "Hello, World"
MSG+="!"          # MSG is now "Hello, World!"

# Building in a loop
RESULT=""
for word in one two three; do
    RESULT+="$word "
done
# RESULT is now "one two three "
```

---

## Command Substitution

```bash
selected=$(find "$START_DIR" -type d 2>/dev/null | fzf ...)
```

**What:** Captures the output of a command into a variable.

**Why:** Use command output as input for other operations.

**Syntax:**
- Modern: `$(command)` - preferred, can be nested
- Legacy: `` `command` `` - avoid, harder to read/nest

**Examples:**
```bash
# Store current date
TODAY=$(date +%Y-%m-%d)

# Store file contents
CONTENT=$(cat file.txt)

# Nested substitution
FILES=$(ls $(dirname "$0"))
```

---

## Conditionals

```bash
if [[ -n "$selected" ]]; then
    realpath "$selected"
fi
```

**What:** Execute code only when conditions are met.

**Why:** Control program flow, handle different cases.

**Syntax:**
```bash
if [[ condition ]]; then
    # commands
elif [[ other_condition ]]; then
    # commands
else
    # commands
fi
```

**Use `[[ ]]` not `[ ]`:** Double brackets are more powerful and safer (no word splitting issues).

**Common Test Operators:**

| Operator | Meaning |
|----------|---------|
| `-n "$VAR"` | String is NOT empty |
| `-z "$VAR"` | String IS empty |
| `-e "$FILE"` | File exists |
| `-d "$PATH"` | Is a directory |
| `-f "$PATH"` | Is a regular file |
| `-r "$FILE"` | File is readable |
| `"$A" == "$B"` | Strings are equal |
| `"$A" != "$B"` | Strings are not equal |
| `$NUM -eq 5` | Numeric equality |
| `$NUM -gt 5` | Greater than |
| `$NUM -lt 5` | Less than |

---

## Pipelines

```bash
find "$START_DIR" -type d 2>/dev/null | fzf --color=...
```

**What:** Connect the output of one command to the input of another.

**Why:** Chain commands together to process data in stages.

**Syntax:** `command1 | command2 | command3`

**How it works:**
1. `command1` runs, its stdout goes to the pipe
2. `command2` reads from the pipe as its stdin
3. Process continues through the chain

**Example breakdown:**
```bash
find "$START_DIR" -type d | fzf
#    ^                    ^
#    |                    |
#    Outputs list of      Reads that list,
#    directories          shows interactive picker
```

---

## Redirections

```bash
find "$START_DIR" -type d 2>/dev/null
```

**What:** Control where command input/output goes.

**Why:** Save output to files, suppress errors, read from files.

**File Descriptors:**
- `0` = stdin (input)
- `1` = stdout (normal output)
- `2` = stderr (error output)

**Common Patterns:**

| Syntax | Meaning |
|--------|---------|
| `> file` | Redirect stdout to file (overwrite) |
| `>> file` | Redirect stdout to file (append) |
| `2> file` | Redirect stderr to file |
| `2>/dev/null` | Discard stderr (send to "black hole") |
| `&> file` | Redirect both stdout and stderr |
| `< file` | Read stdin from file |

**In our script:**
```bash
find "$START_DIR" -type d 2>/dev/null
# Find directories, but suppress "Permission denied" errors
# /dev/null is a special file that discards everything written to it
```

---

## The fd Command

```bash
fd --type d --hidden --exclude node_modules . "$dir"
```

**What:** A modern, fast alternative to `find`. Written in Rust, much faster for large directory trees.

**Why:** Simpler syntax, sensible defaults, and blazing fast performance.

**Installation:**
```bash
brew install fd
```

**Basic Syntax:**
```bash
fd [pattern] [path]
```

**Common Options:**

| Option | Meaning |
|--------|---------|
| `--type d` | Only directories |
| `--type f` | Only files |
| `--hidden` | Include hidden files/dirs (starting with `.`) |
| `--exclude <pattern>` | Skip matching paths |
| `--extension <ext>` | Filter by file extension |
| `--max-depth <n>` | Limit search depth |

**Examples:**
```bash
# Find all directories
fd --type d

# Find all .js files
fd --extension js

# Find directories named "src"
fd --type d src

# Search from specific directory
fd --type d . ~/projects

# Exclude multiple directories
fd --type d \
    --exclude node_modules \
    --exclude .git \
    --exclude dist
```

**Key differences from `find`:**
- Ignores `.git`, `node_modules` by default (respects `.gitignore`)
- Colorized output by default
- Uses regex patterns, not glob
- Much simpler exclusion syntax
- Parallel execution = faster

**In our script:**
```bash
fd --type d --hidden \
    --exclude .git \
    --exclude node_modules \
    --exclude .cache \
    . "$dir" 2>/dev/null
```
- `--type d` → Only directories
- `--hidden` → Include hidden directories
- `--exclude` → Skip these directories
- `.` → Match anything (any name)
- `"$dir"` → Start searching from this directory
- `2>/dev/null` → Suppress permission errors

---

## Quick Reference

```bash
#!/usr/bin/env bash          # Shebang - use bash interpreter
set -uo pipefail             # Strict mode (without -e for interactive tools)

# Dependency checking
command -v fd &>/dev/null || { echo "fd required" >&2; exit 1; }

# Variables
VAR="value"                  # Assignment (no spaces around =)
echo "$VAR"                  # Access (always quote!)
echo "${VAR:-default}"       # Use default if unset

# Functions
my_func() {
    local arg="$1"           # Local variable
    echo "$arg"              # Return via stdout
}
result=$(my_func "hello")    # Capture function output

# Conditionals
if [[ -n "$VAR" ]]; then     # If VAR is not empty
    echo "has value"
fi

# Short-circuit operators
command -v git &>/dev/null || exit 1     # Exit if git missing
[[ -f "$file" ]] && rm "$file"           # Delete only if exists
risky_command || true                     # Ignore errors

# Command grouping
cmd_fails || {
    echo "Error" >&2         # >&2 = redirect to stderr
    exit 1
}

# Pipelines and redirections
cmd1 | cmd2                  # Pipeline - stdout → stdin
cmd 2>/dev/null              # Suppress errors
cmd &>/dev/null              # Suppress all output

# fd (fast find)
fd --type d                              # Find directories
fd --type d --exclude node_modules       # With exclusions
fd --type d --hidden . ~/projects        # Search from path
```

---

*This document is updated as new concepts are used in scripts.*
