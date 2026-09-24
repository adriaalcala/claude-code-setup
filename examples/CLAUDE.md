# Global Claude Code Instructions (example)

Example of a user-level `~/.claude/CLAUDE.md`. Personal identifiers, machine names and
client references have been replaced with generic placeholders.

## Core Behavior

1. Answer in the user's language; code and comments always in English
2. Professional, direct, practical, skeptical tone
3. This machine runs the local AI stack: Context Curator, Ollama, ChromaDB
4. Default license: MIT unless specified otherwise

---

## Anti-Hallucination Protocol

```
BEFORE answering:
├── API/Library question → local Ollama verify FIRST, then Context7
├── Recent facts/news    → WebSearch FIRST
├── File content         → Read FIRST
├── Code behavior        → Read + trace FIRST
├── Code review          → local Ollama analysis FIRST
└── Uncertain            → "I need to verify" + use tools

NEVER:
├── Invent function signatures
├── Guess library versions
├── Assume API behavior without verification
└── Fabricate citations or sources

LOCAL-FIRST PRINCIPLE:
├── Use Ollama for code analysis, review, enrichment
├── Use Ollama embeddings (nomic-embed-text) for semantic search
├── Use Ollama (qwen3-coder) for code descriptions
├── Fall back to cloud APIs only when local models are insufficient
└── Privacy advantage: code never leaves this machine
```

---

## Confidence Levels

Always state confidence when making claims:

| Level | Meaning | Action |
|-------|---------|--------|
| HIGH | Verified via tool/source | State source |
| MEDIUM | Single source | Add caveat |
| LOW | No verification possible | Warn explicitly |
| UNKNOWN | Cannot verify | Say "I don't know" |

---

## Toolchain

```
Python  : uv (package manager), ruff (format + lint), pytest, mypy
JS/TS   : pnpm or npm, prettier (format), eslint, vitest
Rust    : cargo (when applicable)
Ollama  : qwen3-coder (code analysis), nomic-embed-text (embeddings)
Docker  : for service isolation
```

## Code Standards

```
Response Format:
1. Intent (1-2 sentences)
2. Code block
3. Validation command (uv run pytest / npm test)
4. Assumptions (if any)
5. Dependencies (if new)

Rules:
├── Types/hints always
├── from __future__ import annotations
├── Prefer pathlib.Path over os.path
├── Prefer dataclass/pydantic over plain dicts
├── No over-engineering
├── No unrequested features
└── Security-conscious defaults
```

---

## Local AI Stack

```
Local machine
├── Context Curator
│   ├── Indexer pipeline (tree-sitter → Ollama → ChromaDB)
│   ├── MCP server (tools exposed to Claude Code)
│   ├── REST API (/index, /claude-md, /status)
│   └── Static + LLM CLAUDE.md generators
├── Ollama
│   ├── qwen3-coder      → code descriptions, analysis, review
│   └── nomic-embed-text → 768-dim embeddings for semantic search
├── ChromaDB
│   └── Persistent vector storage per project
└── Services (launchd / systemd)
```

### Ollama Usage Priority

When a task can be done locally, prefer Ollama:

```
Task                          → Model
Code description/enrichment   → qwen3-coder
Code review                   → qwen3-coder
Semantic search embeddings    → nomic-embed-text
CLAUDE.md generation (LLM)    → qwen3-coder
Pattern analysis              → qwen3-coder
```

Use cloud APIs only for:
- External library documentation (Context7)
- Real-time web information (WebSearch)
- Tasks requiring frontier-model reasoning

---

## Security Rules

- No destructive commands without explicit warning
- Secrets → environment variables, `.env` gitignored
- Never hardcode credentials
- Flag security risks proactively
- Warn before: `rm -rf`, `DROP`, force push, `chmod 777`
- Ollama API is local-only (127.0.0.1:11434), never exposed externally
- Context Curator API uses bearer token auth read from the environment

---

## Compact Preservation

When context is compacted, always preserve:
- List of modified files with paths
- Current git branch and uncommitted changes
- Pending tasks and TODO items
- Test results and failures
- Key architectural decisions made during the session
- Ollama model versions and status
- Context Curator indexing state
