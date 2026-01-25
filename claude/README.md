# Claude Code - The ~/.claude Directory

This is Claude Code's home directory - Anthropic's agentic coding tool that lives in your terminal.

## What is Claude Code?

Claude Code is an AI coding assistant that:
- **Understands your codebase** - navigates and analyzes any project
- **Writes code** - turns descriptions into working implementations
- **Takes action** - edits files, runs commands, creates commits, opens PRs
- **Debugs** - analyzes errors, finds root causes, implements fixes
- **Automates** - handles tedious tasks like linting, conflicts, docs

Unlike IDE plugins, Claude Code is a **conversational agent** - you describe what you want, it figures out how to do it.

---

## How to Think When Working with Claude Code

### Mental Model

1. **Conversational, not transactional**
   - Describe *what* you want, not *how* to do it
   - Provide context, iterate through multiple turns
   - "Add a login form" vs "Create a file called LoginForm.tsx..."

2. **Agent-based, not tool-based**
   - Claude decides which tools to use
   - You set boundaries (permissions), it finds the path
   - It can plan multi-step workflows autonomously

3. **Context-aware**
   - Learns your codebase structure automatically
   - Reads `CLAUDE.md` for your preferences/conventions
   - Maintains conversation history

4. **Composable & scriptable**
   - Works in pipelines: `git log | claude -p "Create release notes"`
   - Integrates into CI/CD
   - CLI-first design

### Tips for Effective Use

```bash
# Be specific
Bad:  "Fix the bug"
Good: "Fix the login bug where users see blank screen after wrong password"

# Provide context
"Here's the error: [paste]. Expected behavior is X. I tried Y."

# Break complex tasks into steps
"1. Create DB table for profiles
 2. Create API endpoint
 3. Build the UI
 4. Write tests"

# Use CLAUDE.md for conventions
# Document once, Claude follows automatically
```

---

## Key Concepts

### 1. CLAUDE.md (Memory)
Project instructions Claude loads at startup.

**Locations** (in order of precedence):
- `.claude/CLAUDE.md` or `CLAUDE.md` in project root (team-shared)
- `.claude/CLAUDE.local.md` (personal, gitignored)
- `~/.claude/CLAUDE.md` (global personal)
- `.claude/rules/` (modular path-specific rules)

**What to put in CLAUDE.md:**
- Project overview and tech stack
- Coding standards and conventions
- Common workflows
- Architecture notes
- Things to avoid

### 2. Permissions
Control what Claude can do.

```json
// .claude/settings.json or ~/.claude/settings.json
{
  "permissions": {
    "allow": ["Bash(npm run:*)", "Bash(git:*)"],
    "deny": ["Read(.env*)", "WebFetch"],
    "additionalDirectories": ["../shared-lib/"]
  }
}
```

### 3. Hooks
Shell commands that run automatically at specific events.

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "npx prettier --write $file_path"
      }]
    }]
  }
}
```

**Events:** PreToolUse, PostToolUse, UserPromptSubmit, Notification, Stop, etc.

### 4. MCP Servers (Model Context Protocol)
Connect Claude to external tools and data sources.

```bash
# Add a server
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
claude mcp add --transport stdio mydb -- npx @myorg/db-server

# Common servers: GitHub, Jira, PostgreSQL, Sentry, Slack, Notion
```

### 5. Slash Commands
Reusable prompts stored as markdown files.

**Locations:**
- `.claude/commands/` - project commands (shared)
- `~/.claude/commands/` - personal commands

**Example:** `.claude/commands/review.md`
```markdown
---
description: Review code for issues
---
Analyze this code for security, performance, and style issues.
```

**Usage:** `/review` or `/project:review`

### 6. Built-in Commands
```
/help           - Show help
/cost           - Token usage and costs
/context        - Visualize context usage
/compact        - Compress conversation history
/clear          - Clear conversation
/model          - Switch models
/memory         - Edit CLAUDE.md
/permissions    - Manage permissions
/mcp            - Manage MCP servers
/resume         - Continue previous session
/status         - Show current status
```

---

## Directory Structure Explained

### Can Delete Safely (Caches & Temporary Data)

| Path | Description | Delete? |
|------|-------------|---------|
| `cache/` | Temporary cache files | Yes - auto-regenerates |
| `debug/` | Debug logs (69 files) | Yes - only needed for troubleshooting |
| `paste-cache/` | Clipboard paste temporary storage | Yes - transient data |
| `shell-snapshots/` | Shell state snapshots | Yes - auto-recreates |
| `session-env/` | Session environment data | Yes - per-session data |
| `statsig/` | Feature flag cache | Yes - re-fetches automatically |
| `stats-cache.json` | Usage statistics cache | Yes - rebuilds on use |
| `statusline-debug.json` | Debug info for status line | Yes - diagnostic only |
| `telemetry/` | Anonymous usage telemetry | Yes - optional data |

### Important - Keep These

| Path | Description | Keep? |
|------|-------------|-------|
| `settings.json` | Your global settings | **YES** - your config |
| `history.jsonl` | Conversation history | **YES** - enables /resume |
| `todos/` | Todo lists from sessions | Yes - task history |
| `plans/` | Saved implementation plans | Yes - plan history |
| `plugins/` | Installed plugins | Yes - your extensions |
| `projects/` | Project-specific settings | **YES** - per-project config |
| `file-history/` | File editing history | Yes - undo/tracking |
| `downloads/` | Downloaded files | Depends - check contents |
| `statusline-command.sh` | Custom status line script | **YES** - your customization |

### Your Current Files

```
~/.claude/
├── cache/                    # [DELETABLE] Temp cache
├── debug/                    # [DELETABLE] Debug logs
├── downloads/                # [CHECK] Downloaded files
├── file-history/             # [KEEP] Edit history
├── history.jsonl             # [KEEP] Session history (78KB)
├── paste-cache/              # [DELETABLE] Clipboard cache
├── plans/                    # [KEEP] Saved plans
├── plugins/                  # [KEEP] Your plugins
│   ├── known_marketplaces.json
│   └── marketplaces/
├── projects/                 # [KEEP] Project configs
│   ├── -Users-lukasz/
│   ├── -Users-lukasz-Desktop-Tools-dotfiles/
│   └── ... (other projects)
├── session-env/              # [DELETABLE] Session data
├── settings.json             # [KEEP] Your settings
├── shell-snapshots/          # [DELETABLE] Shell states
├── stats-cache.json          # [DELETABLE] Stats cache
├── statsig/                  # [DELETABLE] Feature flags
├── statusline-command.sh     # [KEEP] Custom status line
├── statusline-debug.json     # [DELETABLE] Status debug
├── telemetry/                # [DELETABLE] Telemetry
└── todos/                    # [KEEP] Task lists
```

---

## Your Current Settings

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

You have a custom status line configured. This runs a script to customize the Claude Code UI.

---

## Common Settings You Might Add

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  },

  // Model preference
  "model": "claude-opus-4-5-20251101",

  // Permissions
  "permissions": {
    "allow": [
      "Bash(npm:*)",
      "Bash(git:*)",
      "Bash(make:*)"
    ],
    "deny": [
      "Read(.env*)",
      "Read(**/secrets/**)"
    ]
  },

  // Auto-format after edits
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "prettier --write $file_path 2>/dev/null || true"
      }]
    }]
  },

  // Clean old sessions after 30 days
  "cleanupPeriodDays": 30
}
```

---

## Quick Reference

### Starting Claude Code
```bash
claude                    # Interactive mode
claude -p "query"         # One-shot query
claude -c                 # Continue last session
cat file | claude -p "analyze"  # Piped input
```

### During Session
```
@filename      # Reference a file
/command       # Run a slash command
Ctrl+C         # Cancel current operation
Ctrl+B         # Background current task
Escape         # Exit/cancel
```

### Keyboard Shortcuts
```
Ctrl+L         # Clear screen
Ctrl+R         # Search history
Tab            # Autocomplete
Up/Down        # Navigate history
```

---

## Cleaning Up Space

To free up space, you can safely run:

```bash
# Remove debug logs
rm -rf ~/.claude/debug/*

# Remove cache files
rm -rf ~/.claude/cache/*
rm -rf ~/.claude/paste-cache/*
rm -rf ~/.claude/shell-snapshots/*
rm -rf ~/.claude/session-env/*
rm -rf ~/.claude/statsig/*

# Remove telemetry (if you don't care about it)
rm -rf ~/.claude/telemetry/*

# Remove old todos (careful - check first)
# ls ~/.claude/todos/
# rm ~/.claude/todos/old-session-*
```

**Do NOT delete:**
- `settings.json` - your configuration
- `history.jsonl` - enables session resume
- `projects/` - project-specific settings
- `plugins/` - your installed extensions

---

## Learn More

- `/help` - In-app help
- `claude --help` - CLI help
- Report issues: https://github.com/anthropics/claude-code/issues

---

*This README explains the ~/.claude directory for Claude Code, Anthropic's CLI coding assistant.*
