# Claude Code Crash Course

Master every customization mechanism in Claude Code.

---

## Table of Contents

1. [CLAUDE.md - Project Memory](#1-claudemd---project-memory)
2. [Settings Files](#2-settings-files)
3. [Hooks System](#3-hooks-system)
4. [Slash Commands](#4-slash-commands)
5. [Skills](#5-skills)
6. [Subagents](#6-subagents)
7. [MCP - Model Context Protocol](#7-mcp---model-context-protocol)
8. [CLI Flags & Options](#8-cli-flags--options)
9. [Permission System](#9-permission-system)
10. [IDE Integrations](#10-ide-integrations)
11. [Context Management](#11-context-management)
12. [Git Integration](#12-git-integration)
13. [Plugins](#13-plugins)
14. [Environment Variables](#14-environment-variables)
15. [Keyboard Shortcuts](#15-keyboard-shortcuts)
16. [Quick Reference](#16-quick-reference)

---

## 1. CLAUDE.md - Project Memory

Instructions and context that Claude loads at startup, persisting across sessions.

### Scope Hierarchy (Highest to Lowest Priority)

| Scope | Location | Use Case |
|-------|----------|----------|
| **Enterprise** | `/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS) | Company-wide standards |
| | `/etc/claude-code/CLAUDE.md` (Linux) | |
| | `C:\Program Files\ClaudeCode\CLAUDE.md` (Windows) | |
| **Project** | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team standards (via git) |
| **Project Rules** | `./.claude/rules/*.md` | Path-specific rules |
| **User** | `~/.claude/CLAUDE.md` | Personal preferences |
| **Project Local** | `./CLAUDE.local.md` | Personal per-project (gitignored) |

### Project Rules - Path-Specific Rules

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "src/services/**/*.ts"
---

# API Development Rules

- All endpoints must include input validation
- Use standard error response format
- Include OpenAPI documentation
```

**Glob Patterns:**
- `**/*.ts` - All TypeScript files recursively
- `src/**/*.{ts,tsx}` - Multiple extensions
- `**/test/**` - All test directories

### CLAUDE.md Structure Best Practices

```markdown
# Project Name

## Architecture
Brief description of system architecture.

## Tech Stack
- Frontend: React, TypeScript
- Backend: Node.js, Express
- Database: PostgreSQL

## Conventions
- Use functional components with hooks
- Prefer named exports over default exports
- All API responses use camelCase

## Common Commands
- `npm run dev` - Start development server
- `npm test` - Run test suite
- `npm run build` - Production build

## Important Files
- `src/config/` - Configuration files
- `src/api/` - API route handlers
- `src/utils/` - Shared utilities

## Do Not
- Never commit .env files
- Don't use any in TypeScript
- Avoid console.log in production code
```

### Features

**Imports** - Reference other files:
```markdown
@./docs/api-spec.md
@../shared/conventions.md
```

**View loaded memories:**
```bash
/memory
```

**Bootstrap new project:**
```bash
/init
```

---

## 2. Settings Files

### Scope Hierarchy (Highest to Lowest)

| Priority | Location | Scope |
|----------|----------|-------|
| 1 | System directories | Managed (enterprise) |
| 2 | CLI arguments | Session only |
| 3 | `.claude/settings.local.json` | Project personal |
| 4 | `.claude/settings.json` | Project shared |
| 5 | `~/.claude/settings.json` | User global |

### Complete Settings Reference

```json
{
  "permissions": {
    "allow": ["Bash(npm run:*)", "Read", "Grep"],
    "ask": ["Bash(git push:*)"],
    "deny": ["Bash(rm -rf:*)", "Read(./.env)"],
    "additionalDirectories": ["../docs/"],
    "defaultMode": "default"
  },

  "env": {
    "NODE_ENV": "development",
    "DEBUG": "true"
  },

  "model": "sonnet",

  "hooks": {
    "PreToolUse": [],
    "PostToolUse": [],
    "Stop": []
  },

  "sandbox": {
    "enabled": true,
    "excludedCommands": ["docker"],
    "network": {
      "allowUnixSockets": ["~/.ssh/agent-socket"],
      "allowLocalBinding": true
    }
  },

  "attribution": {
    "commit": "Co-Authored-By: Claude <noreply@anthropic.com>",
    "pr": "Generated with Claude Code"
  },

  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  },

  "fileSuggestion": {
    "type": "command",
    "command": "~/.claude/file-suggest.sh"
  },

  "apiKeyHelper": "~/.claude/get-api-key.sh",

  "respectGitignore": true,
  "cleanupPeriodDays": 30,
  "language": "en",

  "enableAllProjectMcpServers": false,
  "enabledMcpjsonServers": ["github", "slack"],
  "disabledMcpjsonServers": ["risky-server"]
}
```

---

## 3. Hooks System

Event-driven automation that runs before/after Claude actions.

### Hook Events

| Event | Trigger | Can Block | Use Case |
|-------|---------|-----------|----------|
| `PreToolUse` | Before tool runs | Yes | Validate, approve/deny |
| `PostToolUse` | After tool completes | Yes | Format, lint, validate |
| `PermissionRequest` | Permission dialog | Yes | Auto-approve/deny |
| `UserPromptSubmit` | User sends message | Yes | Add context, validate |
| `Stop` | Claude finishes | Yes | Prevent stopping |
| `SubagentStop` | Subagent finishes | Yes | Continue work |
| `Notification` | Notification sent | No | Custom alerts |
| `PreCompact` | Before compaction | No | Logging |
| `SessionStart` | Session begins | No | Setup environment |
| `SessionEnd` | Session ends | No | Cleanup |

### Hook Configuration

**Command Hook:**
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "/path/to/validate.sh",
        "timeout": 60
      }]
    }],
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "prettier --write $FILE"
      }]
    }]
  }
}
```

**Prompt Hook (AI-powered):**
```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "prompt",
        "prompt": "Check if all tests pass before stopping: $ARGUMENTS",
        "timeout": 30
      }]
    }]
  }
}
```

### Hook Input (stdin JSON)

```json
{
  "session_id": "abc123",
  "cwd": "/path/to/project",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm test"
  }
}
```

### Hook Output

**Exit Codes:**
- `0` - Success, continue
- `2` - Block the action
- Other - Non-blocking error

**JSON Response:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "updatedInput": {"command": "npm test --coverage"},
    "additionalContext": "Running in CI mode"
  }
}
```

### Hook Locations

- User: `~/.claude/settings.json`
- Project: `.claude/settings.json`
- In Skills: Inline in SKILL.md frontmatter
- In Commands: Inline in command frontmatter

---

## 4. Slash Commands

### Built-in Commands

| Command | Description |
|---------|-------------|
| `/help` | List all commands |
| `/config` | Configure settings |
| `/cost` | Show token usage |
| `/context` | Show context usage (visual) |
| `/memory` | View loaded memory files |
| `/model` | Switch model |
| `/mcp` | Manage MCP servers |
| `/compact` | Trigger compaction |
| `/plan` | Enter plan mode |
| `/init` | Create CLAUDE.md |
| `/hooks` | View active hooks |
| `/agents` | List subagents |
| `/resume` | Resume session |
| `/rewind` | Undo changes |
| `/vim` | Toggle vim mode |
| `/permissions` | View permissions |
| `/status` | Current status |

### Custom Slash Commands

**Location:**
- Project: `.claude/commands/command-name.md`
- User: `~/.claude/commands/command-name.md`
- Namespaced: `.claude/commands/frontend/test.md` → `/test (project:frontend)`

**Structure:**
```markdown
---
allowed-tools: Bash(git:*), Read, Grep
argument-hint: [branch-name]
description: Create a new feature branch and switch to it
model: haiku
---

Create and switch to a new feature branch named: $ARGUMENTS

1. Check current git status
2. Create branch from main
3. Switch to new branch
4. Confirm success
```

**Frontmatter Options:**

| Field | Description |
|-------|-------------|
| `allowed-tools` | Tools available to command |
| `argument-hint` | Placeholder for arguments |
| `description` | Shown in `/help` |
| `model` | haiku, sonnet, opus |
| `context` | `fork` for isolated subagent |
| `agent` | Subagent type when forked |
| `disable-model-invocation` | Run without AI |
| `hooks` | Command-specific hooks |

**Argument Substitution:**
- `$ARGUMENTS` - All arguments
- `$1`, `$2`, etc. - Individual arguments

**Bash Mode:**
```bash
!git status
!npm run build
```

**File References:**
```markdown
Review @src/api/handler.ts for issues
```

---

## 5. Skills

Model-invoked capabilities that Claude discovers automatically based on descriptions.

### Structure

```
~/.claude/skills/code-review/
├── SKILL.md          # Required - main skill definition
├── reference.md      # Optional - detailed docs
├── examples.md       # Optional - usage examples
└── scripts/
    └── analyze.py    # Optional - helper scripts
```

### SKILL.md Format

```markdown
---
name: code-review
description: Reviews code for quality, security, and best practices. Use when reviewing PRs, checking code quality, or analyzing implementations.
allowed-tools: Read, Grep, Glob, Bash(eslint:*), Bash(npm run lint:*)
model: sonnet
context: fork
agent: general-purpose
user-invocable: true
hooks:
  PostToolUse:
    - matcher: "Read"
      hooks:
        - type: command
          command: "./scripts/log-file-read.sh"
---

# Code Review Skill

You are an expert code reviewer. When reviewing code:

## Checklist
1. Check for security vulnerabilities
2. Verify error handling
3. Assess test coverage
4. Review naming conventions
5. Check for performance issues

## Output Format
Provide findings in this format:
- **Critical**: Must fix before merge
- **Warning**: Should fix
- **Suggestion**: Nice to have

@reference.md
```

### Frontmatter Fields

| Field | Description |
|-------|-------------|
| `name` | Unique identifier (lowercase, hyphens) |
| `description` | When to use (MOST IMPORTANT!) |
| `allowed-tools` | Available tools |
| `model` | sonnet, opus, haiku |
| `context` | `fork` for isolated execution |
| `agent` | Subagent type when forked |
| `user-invocable` | Show in slash command menu |
| `hooks` | Skill-specific hooks |

### Skill Locations

| Scope | Location |
|-------|----------|
| Enterprise | System directories |
| Project | `.claude/skills/skill-name/SKILL.md` |
| User | `~/.claude/skills/skill-name/SKILL.md` |
| Plugin | Bundled in plugins |

### Progressive Disclosure

Keep SKILL.md under 500 lines. Use `@reference.md` to load additional context only when needed:

```markdown
# Main Skill Instructions

For detailed API documentation, see @api-reference.md
For examples, see @examples.md
```

---

## 6. Subagents

Specialized agents for delegating sub-tasks.

### Built-in Subagents

| Agent | Model | Tools | Use Case |
|-------|-------|-------|----------|
| `Explore` | Haiku | Read-only | Fast codebase exploration |
| `Plan` | Inherit | Read-only | Planning and research |
| `general-purpose` | Inherit | All | Complex multi-step tasks |
| `Bash` | Inherit | Bash only | Terminal operations |
| `claude-code-guide` | - | Read-only | Questions about Claude Code |

### Custom Subagent

**Location:**
- Project: `.claude/agents/agent-name.md`
- User: `~/.claude/agents/agent-name.md`

**Structure:**
```markdown
---
name: security-reviewer
description: Security expert. Use when reviewing code for vulnerabilities, checking dependencies, or auditing access controls.
tools: Read, Glob, Grep, Bash(npm audit:*)
disallowedTools: Write, Edit
model: opus
permissionMode: default
skills: security-checklist
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./validate-command.sh"
---

You are a security expert specializing in:
- OWASP Top 10 vulnerabilities
- Dependency auditing
- Access control review
- Secrets detection

When analyzing code:
1. Check for injection vulnerabilities
2. Review authentication/authorization
3. Audit third-party dependencies
4. Verify secrets management
```

### Frontmatter Fields

| Field | Description |
|-------|-------------|
| `name` | Identifier |
| `description` | When to delegate |
| `tools` | Allowed tools (allowlist) |
| `disallowedTools` | Blocked tools (denylist) |
| `model` | sonnet, opus, haiku, inherit |
| `permissionMode` | See below |
| `skills` | Skills to load |
| `hooks` | Agent-specific hooks |

### Permission Modes

| Mode | Behavior |
|------|----------|
| `default` | Standard permission prompts |
| `acceptEdits` | Auto-accept file edits |
| `dontAsk` | Auto-deny non-approved tools |
| `bypassPermissions` | Skip all checks |
| `plan` | Read-only mode |

### Using Subagents

Claude automatically delegates to appropriate subagents, or you can invoke:

```bash
/agents                    # List available agents
```

Via CLI:
```bash
claude --agent security-reviewer "Review auth module"
```

---

## 7. MCP - Model Context Protocol

External tool integration via standardized protocol.

### Transport Types

| Type | Use Case | Example |
|------|----------|---------|
| `http` | Cloud services | Stripe, GitHub |
| `stdio` | Local processes | Custom scripts |
| `sse` | Server-sent events | Legacy (deprecated) |

### Adding MCP Servers

**HTTP Server:**
```bash
claude mcp add --transport http github https://api.github.com/mcp
```

**Local Server:**
```bash
claude mcp add --transport stdio database \
  --env DB_URL=postgresql://localhost/mydb \
  -- npx -y @myorg/db-mcp-server
```

**With Scope:**
```bash
claude mcp add --transport http paypal --scope project https://mcp.paypal.com
claude mcp add --transport http internal --scope user https://internal.company.com/mcp
```

### Scopes

| Scope | Storage | Shared |
|-------|---------|--------|
| `local` | `~/.claude.json` | No |
| `project` | `.mcp.json` | Yes (git) |
| `user` | `~/.claude.json` | Across projects |

### .mcp.json Format

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.github.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${GITHUB_TOKEN}"
      }
    },
    "database": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@company/db-mcp"],
      "env": {
        "DB_URL": "${DB_URL:-postgresql://localhost/dev}"
      }
    },
    "internal-api": {
      "type": "http",
      "url": "https://api.internal.com/mcp",
      "timeout": 30000
    }
  }
}
```

### Environment Variable Expansion

- `${VAR}` - Expand variable
- `${VAR:-default}` - With fallback
- Works in: `command`, `args`, `env`, `url`, `headers`

### MCP Commands

```bash
claude mcp list                      # List all servers
claude mcp get github                # Server details
claude mcp remove github             # Remove server
claude mcp reset-project-choices     # Clear approvals
claude mcp add-from-claude-desktop   # Import from desktop app
```

In session:
```bash
/mcp                                 # Manage servers, OAuth setup
```

### Using MCP Tools

MCP tools appear as regular tools:
```
mcp__github__create_issue
mcp__database__query
```

MCP prompts as slash commands:
```bash
/mcp__github__review_pr 123
```

MCP resources via @-mentions:
```
@mcp__database__schema://users
```

---

## 8. CLI Flags & Options

### Essential Flags

```bash
claude                              # Interactive REPL
claude "query"                      # Start with prompt
claude -p "query"                   # Print mode (non-interactive)
claude -c                           # Continue last session
claude -r "session-id"              # Resume specific session
```

### Model & Debug

```bash
claude --model opus                 # Use specific model
claude --model haiku                # Fast, cheap model
claude --debug "api,mcp"            # Debug specific features
claude --debug "all"                # Full debug output
```

### Customization

```bash
claude --add-dir ../docs            # Add working directory
claude --permission-mode plan       # Start in plan mode
claude --tools "Bash,Read,Edit"     # Restrict tools
claude --allowedTools "Bash(npm:*)" # Pre-approve patterns
claude --disallowedTools "Write"    # Block specific tools
```

### Agent & Plugin

```bash
claude --agent security-reviewer    # Use custom agent
claude --agents '{"name": {...}}'   # Define inline
claude --plugin-dir ./my-plugin     # Load plugin
```

### System Prompt

```bash
claude --append-system-prompt "Always use TypeScript"
claude --system-prompt "You are a Python expert"
```

### Print Mode (Automation)

```bash
claude -p "query"                          # Basic print mode
claude -p --output-format json "query"     # JSON output
claude -p --json-schema '{"type":"object"}' "query"  # Structured
claude -p --max-turns 5 "query"            # Limit iterations
claude -p --max-budget-usd 10 "query"      # Token budget
claude -p --no-session-persistence "query" # Don't save
```

### Configuration Files

```bash
claude --settings ./custom-settings.json
claude --mcp-config ./mcp-servers.json
```

---

## 9. Permission System

### Permission Rules Syntax

**In settings.json:**
```json
{
  "permissions": {
    "allow": [
      "Read",
      "Grep",
      "Glob",
      "Bash(npm run:*)",
      "Bash(git status)",
      "Bash(git diff:*)"
    ],
    "ask": [
      "Bash(git push:*)",
      "Bash(git commit:*)"
    ],
    "deny": [
      "Bash(rm -rf:*)",
      "Bash(curl:*)",
      "Read(./.env)",
      "Read(./secrets/**)"
    ],
    "additionalDirectories": ["../shared/", "../docs/"],
    "defaultMode": "default"
  }
}
```

### Pattern Syntax

**Bash Commands:**
```
Bash                    # All commands
Bash(npm run:*)         # Prefix match (npm run anything)
Bash(npm *)             # Wildcard (npm followed by anything)
Bash(git * main)        # Middle wildcard
```

**File Patterns:**
```
Read(src/**)            # Relative to settings file
Read(./src/**)          # Relative to cwd
Read(//tmp/*)           # Absolute path
Read(~/.config/*)       # Home directory
Edit(**/*.test.ts)      # Glob patterns
```

**WebFetch:**
```
WebFetch(domain:github.com)
WebFetch(domain:*.company.com)
```

**MCP Tools:**
```
mcp__github              # All GitHub tools
mcp__github__create_issue  # Specific tool
mcp__*__read_*           # Pattern match
```

**Subagents:**
```
Task(Explore)            # Specific subagent
Task(*)                  # All subagents
```

### Permission Modes

| Mode | Description |
|------|-------------|
| `default` | Prompt for unknown tools |
| `plan` | Read-only exploration |
| `acceptEdits` | Auto-accept file changes |
| `dontAsk` | Auto-deny unpre-approved |
| `bypassPermissions` | Skip all (dangerous) |

Switch modes:
```bash
/plan                   # Enter plan mode
Shift+Tab               # Cycle modes
```

---

## 10. IDE Integrations

### VS Code

1. Install "Claude Code" from marketplace
2. Open Claude panel (Ctrl/Cmd+Shift+P → "Claude")
3. Use inline chat or terminal mode

**Features:**
- Inline code suggestions
- Terminal integration
- File context awareness
- Selection-based queries

### JetBrains (IntelliJ, PyCharm, WebStorm, etc.)

1. Preferences → Plugins → "Claude Code"
2. Configure in Settings → Claude Code
3. Access via tool window

### Chrome Extension

- Test local web applications
- Browser automation
- Form filling, data extraction

### Auto-Connect

```bash
claude --ide                        # Auto-detect IDE
```

---

## 11. Context Management

### Context Window

- Default: ~200K tokens
- Extended: Up to 1M with special models
- Monitor: `/context` (visual grid)

### Auto-Compaction

Triggers at ~95% capacity:
- Summarizes older messages
- Preserves recent context
- Maintains key information

Override threshold:
```bash
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50
```

Manual compaction:
```bash
/compact
```

### @-Mentions

```
@filename.ts            # Include file
@directory/             # Include listing
@mcp__server__resource  # MCP resource
```

Fuzzy search works in autocomplete.

### Memory Loading Order

1. Enterprise CLAUDE.md (highest)
2. Project CLAUDE.md
3. Project rules (`.claude/rules/*.md`)
4. User CLAUDE.md
5. Project local (`.claude/CLAUDE.local.md`)
6. Nested directory CLAUDE.md

---

## 12. Git Integration

### Automatic Features

- Repository detection
- Branch awareness
- Commit attribution
- PR creation

### Commands

```bash
/rewind                 # Undo changes + conversation
/resume                 # Resume session by ID
/rename [name]          # Name current session
```

### Attribution

In `settings.json`:
```json
{
  "attribution": {
    "commit": "Co-Authored-By: Claude <noreply@anthropic.com>",
    "pr": "Generated with Claude Code"
  }
}
```

### Session Persistence

Sessions stored in `~/.claude/projects/`

Resume:
```bash
claude -c               # Last session
claude -r abc123        # By ID
claude -r "feature-x"   # By name
```

---

## 13. Plugins

Complete bundles of Claude Code extensions.

### Plugin Structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json     # Plugin manifest
├── commands/           # Slash commands
├── agents/             # Subagents
├── skills/             # Skills
├── hooks/
│   └── hooks.json      # Hook definitions
├── .mcp.json           # MCP servers
└── .lsp.json           # Language servers
```

### plugin.json

```json
{
  "name": "my-awesome-plugin",
  "version": "1.0.0",
  "description": "Adds awesome features",
  "author": "Your Name",
  "homepage": "https://github.com/you/plugin"
}
```

### Distribution

| Source | Format |
|--------|--------|
| GitHub | `github:owner/repo` |
| npm | `npm:package-name` |
| URL | `https://example.com/plugin.zip` |
| Local | `file:./path/to/plugin` |

### Installation

```bash
claude plugin add github:company/plugin
claude plugin add npm:@company/claude-plugin
```

### Management

```bash
/plugin                 # List/manage plugins
/plugin add [source]    # Add plugin
/plugin remove [name]   # Remove plugin
```

---

## 14. Environment Variables

### API Configuration

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export ANTHROPIC_MODEL="claude-opus-4"
```

### Provider Selection

```bash
export CLAUDE_CODE_USE_BEDROCK=1      # AWS Bedrock
export CLAUDE_CODE_USE_VERTEX=1       # Google Vertex
```

### Behavior Control

```bash
export CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1  # Stay in project
export CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1       # No background
export MAX_MCP_OUTPUT_TOKENS=50000                  # MCP limit
export ENABLE_TOOL_SEARCH=auto:5                    # Tool search
```

### Debug & Development

```bash
export IS_DEMO=true                   # Hide email, skip onboarding
export DISABLE_AUTOUPDATER=1          # No auto-updates
export DISABLE_TELEMETRY=1            # No telemetry
```

### Thinking Mode

```bash
export MAX_THINKING_TOKENS=50000      # Thinking budget
```

---

## 15. Keyboard Shortcuts

### Navigation

| Shortcut | Action |
|----------|--------|
| `Ctrl+C` | Cancel current operation |
| `Ctrl+D` | Exit session |
| `Ctrl+L` | Clear screen |
| `Ctrl+R` | Reverse search history |

### During Execution

| Shortcut | Action |
|----------|--------|
| `Ctrl+B` | Background current task |
| `Esc+Esc` | Rewind changes |
| `Shift+Tab` | Cycle permission modes |

### Input

| Shortcut | Action |
|----------|--------|
| `Shift+Enter` | Multiline input |
| `\` + Enter | Alternative multiline |
| `Ctrl+V` | Paste image |
| `/` | Slash commands |
| `!` | Bash mode |
| `@` | File autocomplete |

### Model Control

| Shortcut | Action |
|----------|--------|
| `Alt+P` | Switch model |
| `Alt+T` | Toggle thinking mode |
| `Ctrl+O` | Toggle verbose output |

### Text Editing

| Shortcut | Action |
|----------|--------|
| `Ctrl+K` | Delete to end of line |
| `Ctrl+U` | Delete entire line |
| `Ctrl+Y` | Paste deleted text |
| `Alt+B/F` | Move by word |

---

## 16. Quick Reference

### What to Use When

| Need | Mechanism | Location |
|------|-----------|----------|
| Project instructions | CLAUDE.md | `./CLAUDE.md` |
| Path-specific rules | Rules | `.claude/rules/*.md` |
| Personal preferences | User memory | `~/.claude/CLAUDE.md` |
| Auto-run on events | Hooks | `settings.json` |
| Pre-approve tools | Permissions | `settings.json` |
| Manual invoke prompts | Slash commands | `.claude/commands/` |
| Auto-discovered capabilities | Skills | `.claude/skills/` |
| Delegate specialized tasks | Subagents | `.claude/agents/` |
| External tools | MCP | `.mcp.json` |
| Bundle everything | Plugins | `.claude-plugin/` |

### File Locations Summary

```
Project Root/
├── CLAUDE.md                    # Project memory
├── CLAUDE.local.md              # Personal (gitignored)
├── .mcp.json                    # MCP servers (shared)
└── .claude/
    ├── CLAUDE.md                # Alternative location
    ├── settings.json            # Project settings (shared)
    ├── settings.local.json      # Personal settings
    ├── rules/
    │   └── *.md                 # Path-specific rules
    ├── commands/
    │   └── *.md                 # Custom commands
    ├── agents/
    │   └── *.md                 # Custom subagents
    └── skills/
        └── skill-name/
            └── SKILL.md         # Custom skills

~/.claude/
├── CLAUDE.md                    # User memory (all projects)
├── settings.json                # User settings
├── commands/                    # Personal commands
├── agents/                      # Personal agents
└── skills/                      # Personal skills
```

### Priority Order (Highest to Lowest)

1. CLI flags
2. Managed/Enterprise settings
3. Project local settings
4. Project shared settings
5. User settings
6. Defaults

---

## Next Steps

1. Create a `CLAUDE.md` in your project with key architecture info
2. Set up permissions in `.claude/settings.json` for common operations
3. Create custom slash commands for repetitive tasks
4. Add MCP servers for external integrations
5. Build skills for complex, reusable workflows
6. Define subagents for specialized tasks

Master these mechanisms to unlock the full power of Claude Code.
