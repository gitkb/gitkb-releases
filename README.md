# GitKB

**Knowledge engineering for software teams.**

`git-kb` is a git-like CLI for knowledge engineering — the discipline of structuring, connecting, and distributing the knowledge that drives software development. It brings code intelligence, graph-connected documents, and persistent context to humans and AI agents alike.

[GitKB.com](https://gitkb.com) is the knowledge engineering platform built on top. Local and free forever. Cloud sync for teams coming soon.

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

# Try it
git kb code symbols --search "auth"
git kb code callers authenticate
git kb search "how does login work"

# Create your first document
git kb create --type task --title "Refactor auth module"
git kb board
```

## Connect to Your AI Editor

GitKB exposes 42 MCP tools. Add to your editor config:

**Claude Code** (`.claude/settings.json` or project `.mcp.json`):
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

Works with **Claude Code**, **Cursor**, **Cline**, **Windsurf**, and any MCP-compatible editor.

### Claude Code Plugin

If you use Claude Code, install the GitKB plugin for skills and `/kb-*` slash commands:

```bash
claude mcp add gitkb -- git-kb mcp
```

Or add the MCP config above manually. Both approaches give you 42 MCP tools. The plugin additionally provides 4 skills and 12 `/kb-*` slash commands — see [the Claude Code guide](https://gitkb.com/docs/getting-started/claude-code/) for details.

## What You Get

### Knowledge Base

Everything is a document — tasks, specs, incidents, architecture decisions, context. Markdown with YAML frontmatter. Linked with `[[wikilinks]]`. Version-controlled with BLAKE3 integrity.

```bash
git kb create --type task --title "Fix login timeout"
git kb checkout tasks/fix-login-timeout
# edit .kb/workspace/tasks/fix-login-timeout.md
git kb commit -m "Add acceptance criteria"
git kb board
git kb graph tasks/fix-login-timeout
```

### Code Intelligence

AST-based understanding across 17 languages. Not text search — structural analysis.

```bash
git kb code symbols --search "UserService"     # Find symbols
git kb code callers UserService                 # Who calls this?
git kb code callees UserService                 # What does it call?
git kb code impact src/auth.rs                  # Blast radius
git kb code dead src/                           # Find dead code
```

**Supported languages:** Rust, TypeScript, JavaScript, Python, Go, Java, C, C++, C#, Ruby, Kotlin, Swift, Scala, Elixir, Lua, PHP, Haskell

### A Home for Everything That Isn't Code

Specs, ADRs, runbooks, incident reports, design decisions, architecture docs — engineering teams produce a growing corpus of documents that have no proper home. They end up scattered across Google Docs, Notion, wikis, or random markdown files in repos. GitKB gives them a single place: versioned, linked to code, and queryable by both humans and agents.

- **Typed documents** — tasks, specs, incidents, epics, notes, context, each with structured frontmatter
- **Graph-connected** — `[[wikilinks]]` link documents to each other and to code symbols
- **Task tracking** — kanban board, status workflows, acceptance criteria
- **Persistent agent memory** — context documents, session handoff, work that survives across sessions

### 42 MCP Tools

Full read/write access to the knowledge base for any AI agent:

| Category | Examples |
|----------|---------|
| Documents | `kb_create`, `kb_show`, `kb_list`, `kb_commit` |
| Board & Graph | `kb_board`, `kb_graph`, `kb_smart_context` |
| Code Intel | `kb_symbols`, `kb_callers`, `kb_callees`, `kb_impact`, `kb_dead_code` |
| Search & AI | `kb_search`, `kb_semantic` |

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

[Join the alpha →](https://gitkb.com/local-alpha)

## License

MIT
