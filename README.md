# GitKB

**Knowledge engineering for software teams.**

GitKB is a git-like distributed knowledge graph protocol with sparse sync and checkout semantics, enabling agents and their humans to work on all the world's knowledge — a few documents at a time.

```bash
brew install harmony-labs/tap/gitkb
```

## What It Does

- **Distributed knowledge protocol** — a git-like protocol for sharing and maintaining context that spans repositories. Humans and agents push, pull, and sync documents with sparse checkout semantics. No need to clone — pull only the docs you need for the task at hand.
- **Documents are just files** — Markdown with YAML frontmatter. No proprietary format, no vendor lock-in. Your knowledge is yours.
- **Automatic knowledge graph** — your documents are automatically indexed into a lightning-fast, searchable graph of relationships. Full-text search and vector search (alpha) included.
- **Code intelligence** — AST-based call graphs, impact analysis, and dead code detection across 17 languages via tree-sitter. Symbols and references are first-class nodes in the same graph.
- **CLI** — `git kb` commands for every operation. Scriptable, composable, works in CI.
- **MCP tools** — full read/write access to the KB and code intelligence from Claude Code, Cursor, Cline, Windsurf, or any MCP-compatible editor.
- **Task tracking** — kanban board, status workflows, acceptance criteria, assignment.
- **Local-first** — everything on your machine, no account required, free forever.

## Quick Start

```bash
brew install harmony-labs/tap/gitkb
# or: curl -fsSL https://get.gitkb.com/install.sh | bash

cd your-project
git kb init

# Index your code
git kb code index .

# Understand your codebase
git kb code callers authenticate
git kb code impact src/auth.rs
git kb code dead src/

# Track a bug you found
git kb create --type incident --title "Auth timeout on token refresh"
git kb board
```

## Connect to Your AI Editor

Add to `.mcp.json` in your project root:

```json
{
  "mcpServers": {
    "gitkb": {
      "command": "git-kb",
      "args": ["mcp"]
    }
  }
}
```

Works with Claude Code, Cursor, Cline, Windsurf, and any MCP-compatible editor.

### Claude Code

For slash commands like `/kb-board`, `/kb-start`, and `/kb-close` that let you manage tasks without leaving the conversation:

```bash
git kb init claude
```

See [the Claude Code guide](https://gitkb.com/docs/getting-started/claude-code/) for details.

## Try Asking Your Agent

- "What functions call `authenticate()`?"
- "What's the blast radius of changing `src/auth.rs`?"
- "Create a task for the login bug"
- "Show me the board"
- "Find dead code in `src/services/`"

## Install Options

| Method | Command |
|--------|---------|
| Homebrew | `brew install harmony-labs/tap/gitkb` |
| Install script | `curl -fsSL https://get.gitkb.com/install.sh \| bash` |
| Cargo binstall | `cargo binstall gitkb-cli` |
| Specific version | `VERSION=0.1.38 curl -fsSL https://get.gitkb.com/install.sh \| bash` |

Checksums are published on the [releases page](https://github.com/harmony-labs/gitkb-releases/releases).

## Documentation

- [Getting Started](https://gitkb.com/docs/getting-started/quick-start/)
- [Installation](https://gitkb.com/docs/getting-started/installation/)
- [MCP Setup](https://gitkb.com/docs/getting-started/mcp-setup/)
- [Claude Code](https://gitkb.com/docs/getting-started/claude-code/)
- [Code Intelligence](https://gitkb.com/docs/core-concepts/code-intelligence/)
- [CLI Reference](https://gitkb.com/docs/cli-reference/)

## Cloud Sync

GitKB works fully offline. When you're ready, sync your KB across your team.

[GitKB.com](https://gitkb.com) · [Join the alpha →](https://gitkb.com/local-alpha)
