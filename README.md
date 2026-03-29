# GitKB

**Knowledge engineering for software teams.**

Specs, ADRs, runbooks, incident reports, tasks, architecture decisions — engineering teams produce a growing corpus of knowledge that ends up scattered across Google Docs, Notion, wikis, or loose markdown files. `git-kb` gives it all a single home: versioned, graph-connected, queryable, and accessible to both humans and AI agents.

```bash
brew install harmony-labs/tap/gitkb
```

## What It Does

- **Knowledge base** — typed documents (tasks, specs, incidents, epics, context) with structured frontmatter, `[[wikilinks]]`, and version control with BLAKE3 integrity
- **Code intelligence** — AST-based call graphs, impact analysis, and dead code detection across 17 languages via tree-sitter
- **Graph** — every document and code symbol linked by typed relationships, traversable in milliseconds
- **42 MCP tools** — full read/write access for Claude Code, Cursor, Cline, Windsurf, and any MCP-compatible editor
- **Task tracking** — kanban board, status workflows, acceptance criteria
- **Persistent agent memory** — context that survives across sessions, compactions, and handoffs
- **Local-first** — everything runs on your machine, no account required, free forever

## Install

### Homebrew (macOS / Linux)

```bash
brew install harmony-labs/tap/gitkb
```

### Install script (macOS / Linux)

```bash
curl -fsSL https://get.gitkb.com/install.sh | bash
```

### Cargo binstall

```bash
cargo binstall gitkb-cli
```

### Specific version

```bash
VERSION=0.1.38 curl -fsSL https://get.gitkb.com/install.sh | bash
```

Checksums for each release are published on the [GitHub releases page](https://github.com/harmony-labs/gitkb-releases/releases).

### Verify

```bash
git kb --version
```

## Quick Start

```bash
# Initialize in any project
cd your-project
git kb init

# Index your code (17 languages supported)
git kb code index .

# Query your codebase
git kb code symbols --search "auth"
git kb code callers authenticate
git kb code impact src/auth.rs

# Create and manage knowledge
git kb create --type task --title "Refactor auth module"
git kb board
git kb search "how does login work"
```

## Connect to Your AI Editor

GitKB exposes 42 MCP tools. Add to your editor config:

**Claude Code**, **Cursor**, **Cline**, **Windsurf** (`.mcp.json` in your project root):
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

Or via the Claude Code CLI:
```bash
claude mcp add gitkb -- git-kb mcp
```

### Claude Code Integration

For the full experience — skills, rules, and 12 `/kb-*` slash commands:

```bash
git kb init claude
```

This scaffolds rules, skills, and commands that teach Claude how to use GitKB effectively. See [the Claude Code guide](https://gitkb.com/docs/getting-started/claude-code/) for details.

## MCP Tools

| Category | Tools |
|----------|-------|
| Documents | `kb_create`, `kb_show`, `kb_list`, `kb_commit`, `kb_checkout`, `kb_status`, `kb_diff` |
| Board & Graph | `kb_board`, `kb_graph`, `kb_smart_context` |
| Code Intel | `kb_symbols`, `kb_callers`, `kb_callees`, `kb_impact`, `kb_dead_code` |
| Search | `kb_search`, `kb_semantic` |

## Documentation

- [Getting Started](https://gitkb.com/docs/getting-started/quick-start/)
- [Installation](https://gitkb.com/docs/getting-started/installation/)
- [MCP Setup](https://gitkb.com/docs/getting-started/mcp-setup/)
- [Claude Code Guide](https://gitkb.com/docs/getting-started/claude-code/)
- [Code Intelligence](https://gitkb.com/docs/core-concepts/code-intelligence/)
- [CLI Reference](https://gitkb.com/docs/cli-reference/)

## Cloud Sync (Coming Soon)

GitKB works fully offline. Cloud sync for teams is coming:

```bash
git kb login
git kb push
git kb pull
```

[GitKB.com](https://gitkb.com) · [Join the alpha →](https://gitkb.com/local-alpha)

## License

MIT
