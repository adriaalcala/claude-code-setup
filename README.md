# claude-code-setup

My working configuration for [Claude Code](https://claude.com/claude-code): subagents, hooks,
skills, slash commands and language rules, extracted from a real day-to-day setup and published
as a reference.

The guiding principle is **local-first verification**. Before Claude asserts anything about an API,
a library version or a piece of code, a local model (Ollama) checks it against the actual source.
Cloud calls are reserved for things that genuinely need frontier reasoning or live web data. The
second principle is **fail-closed guardrails**: hooks sit between Claude and the filesystem/shell,
and they deny by default when something looks dangerous or ambiguous.

> Everything here has been sanitized. Client names, internal hosts, absolute paths, emails and
> tokens were replaced with generic placeholders. Files that could not be meaningfully sanitized
> were left out — see [What is not here](#what-is-not-here).

---

## Layout

```
.
├── agents/     16 subagent definitions (Task-tool personas)
├── commands/   4 slash commands
├── hooks/
│   └── scripts/  12 lifecycle hook scripts (bash)
├── skills/     20 skills (SKILL.md + assets for browser-uat)
├── rules/      Language-specific coding standards (Python, TypeScript)
└── examples/   settings.json and CLAUDE.md templates
```

---

## Agents

Subagents are spawned for focused, bounded work so the main conversation keeps its context clean.

Agents that declare frontmatter use the `opus` model alias rather than a pinned model ID, so they
keep working across model releases, and they list the standard Claude Code tools (`Read`, `Write`,
`Edit`, `Grep`, `Glob`, `Bash`, `WebFetch`, `Task`). Tool access is scoped per agent: the planning
agent cannot write, and only agents that actually shell out get `Bash`.

| Agent | What it does | Why I use it |
|---|---|---|
| `analyzer` | Post-hoc analysis of why one output beat another, extracting reusable improvement patterns. | Turns one-off wins into rules I can fold back into skills. |
| `check-agent` | Validates code quality, security and architectural compliance against project conventions. | The gate between every stage of the `/workflow` pipeline — nothing advances unreviewed. |
| `code-reviewer` | Thorough review pass over a diff or file: correctness, design, tests, style. | Catches the class of bug that only shows up when someone reads the whole change at once. |
| `comparator` | Blind A/B comparison of two outputs without knowing their origin. | Removes my own bias when deciding whether a prompt or skill change actually helped. |
| `curator-admin` | Administers the Context Curator stack: indexing, ChromaDB collections, Ollama health. | Keeps the semantic index healthy without me memorizing the API surface. |
| `documentation-agent` | Writes documentation for features once they are implemented. | Documentation written in the same session as the code, while the context is still there. |
| `grader` | Scores an output against explicit expectations, no partial credit. | Gives skill iteration an objective signal instead of "looks fine to me". |
| `implementation-agent` | Executes a planned implementation task: code generation and edits. | The worker stage of the pipeline — plans in, diffs out. |
| `incident-responder` | Production incident triage: severity, evidence correlation, root cause, mitigation. | Structure under pressure, so I investigate instead of guessing at 3am. |
| `planning-agent` | Turns requirements into a structured, ordered implementation plan. | Forces the plan to exist before code does. |
| `research-synthesizer` | Researches a topic, evaluates sources and synthesizes with citations. | Research with traceable sources, which is the whole point of the anti-hallucination rules. |
| `security-auditor` | Audits for vulnerabilities, leaked secrets and misconfigurations; produces a report. | A deliberate security pass that doesn't depend on me remembering to ask for one. |
| `sync-agent` | Handles git integration and knowledge-base synchronization. | Keeps the project knowledge directory in step with what actually landed in git. |
| `system-monitor` | Reports local machine health: CPU, RAM, disk, GPU, Ollama, Docker, services. | The local AI stack has moving parts; this tells me which one is down. |
| `test-agent` | Designs and runs test strategies and suites. | Tests get designed from requirements rather than reverse-engineered from the implementation. |
| `workflow-agent` | Orchestrates the full multi-agent pipeline with local-first verification at each step. | One entry point for "build this properly" instead of driving each agent by hand. |

---

## Hooks

Hooks are plain bash, registered in `settings.json` against Claude Code lifecycle events. They are
deliberately boring and fail-closed: on error they deny rather than allow.

### PreToolUse — run before a tool executes, can block it

| Hook | What it does | Why I use it |
|---|---|---|
| `bash-guard.sh` | Matches the command against a deny list (`rm -rf /`, `mkfs`, `curl \| bash`, piped sudo, writes to `/etc/passwd`…) and an allow list. Denies on any error. | The single highest-value guardrail: an agent with shell access needs a hard floor it cannot argue its way past. |
| `write-guard.sh` | Blocks writes to system paths and to files that look like secrets (`*.pem`, `*id_rsa*`, `.env.production`, `*credentials*`), and scans content for secret-shaped assignments. | Stops credentials from being written into the repo, accidentally or otherwise. |
| `dependency-check.sh` | Audits pip/npm packages for known vulnerabilities before an install command runs. | Supply-chain problems are much cheaper to catch before `install` than after. |
| `git-branch-guard.sh` | Detects commits and pushes targeting `main`, `master`, `develop` or `release/*` and blocks them. | Protected branches, enforced locally instead of hoped for. |

### PostToolUse — run after a tool executes

| Hook | What it does | Why I use it |
|---|---|---|
| `write-format.sh` | Auto-formats the file that was just written (ruff / prettier / black by file type). | Formatting stops being a review topic. Every file is canonical the moment it lands. |
| `bash-vuln.sh` | Scans for known security issues in dependencies after an install completes. | The second half of the dependency check, once the real tree is resolved. |
| `work-log-commit.sh` | Detects a successful `git commit` and appends it to a dated JSON work log. | A commit-accurate activity log I did not have to maintain by hand. |
| `cost-tracker.sh` | Logs tool usage and estimated token cost to CSV. | Makes the cost of a given working style visible instead of arriving as a monthly surprise. |
| `posttooluse-failure.sh` | Logs tool failures with rotation, redacting secrets and home paths from the captured error. | Failure context for debugging, without the log itself becoming a leak. |

### Session lifecycle

| Hook | What it does | Why I use it |
|---|---|---|
| `session-start.sh` | Detects the project (git / node / python / go), checks Ollama, Context Curator and ChromaDB, and seeds the session context. | Claude starts every session already knowing where it is and which services are reachable. |
| `env-validator.sh` | Validates the local environment at startup: Ollama running, required models pulled, dependencies present. | Fails loudly at second zero instead of halfway through a task. |
| `stop.sh` | On session end, produces a git summary and a final context snapshot, and records service state. | A written handover to my next session. |

---

## Skills

Skills are progressive-disclosure instruction files: Claude loads the full body only when the task
matches. Grouped by what they are for.

### Verification and code quality

| Skill | What it does | Why I use it |
|---|---|---|
| `anti-hallucination` | Enforces the verification protocol — check code and claims with local Ollama before answering. | The core rule of this setup. An unverified claim about an API is worse than no answer. |
| `ollama-verify` | Runs local models to verify code, review implementations and analyze patterns. | Reviews that never send proprietary code to a cloud API. |
| `refactor-analyzer` | Finds refactoring opportunities scored by impact and effort: smells, complexity hotspots, duplication, coupling. | Turns "this needs cleaning up" into a ranked list I can actually work through. |
| `code-patterns` | Quick reference for REST APIs, pytest, Docker, GitHub Actions, Python async and TypeScript. | Keeps generated code idiomatic to the patterns I already use. |
| `commit-message` | Writes semantic commit messages following Conventional Commits. | Conventional commits are the input to automated versioning and changelogs. |

### Git and delivery

| Skill | What it does | Why I use it |
|---|---|---|
| `git-detective` | Git archaeology: blame, log, bisect, finding commits by message or content, tracing renames. | Answers "why is this code like this?" from the record instead of from speculation. |
| `backup-snapshot` | Creates a tagged git snapshot before risky operations and documents the recovery steps. | A guaranteed way back before letting an agent loose on a large refactor. |
| `release-manager` | Semantic versioning derived from commits, changelog generation, tags and release notes. | Releases become mechanical, which is the only way they stay consistent. |
| `ci-cd-builder` | Generates GitHub Actions / GitLab CI pipelines, detecting language, test runner and linters. | Every new project gets real CI on day one rather than "later". |
| `project-bootstrapper` | Scaffolds a project complete with `.claude/` config, CI/CD, tests and docs (Python, TypeScript, FastAPI, React, CLI). | New repos start with the whole setup already wired in. |

### Local AI stack

| Skill | What it does | Why I use it |
|---|---|---|
| `ollama-model-manager` | Lists, pulls, removes, benchmarks and compares Ollama models with size and quantization detail. | Picking a model becomes a measurement rather than a guess. |
| `context-curator-admin` | Admin operations for Context Curator: indexing, monitoring, CLAUDE.md generation. | The operational half of the semantic index — see below. |
| `prompt-engineer` | Builds and optimizes prompts: patterns, few-shot, chain-of-thought, output formatting; tests locally first. | Prompt iteration against a local model costs nothing, so I iterate more. |
| `skill-creator` | Designs and iterates on skills with a structured evaluation framework and test coverage. | Skills get evaluated like code instead of being written once and trusted forever. |

### Testing and operations

| Skill | What it does | Why I use it |
|---|---|---|
| `browser-uat` | Runs acceptance tests against a real Chrome instance via the DevTools Protocol and Playwright, driving a natural-language test description. | Tests the app in the browser I actually use, with real sessions — no separate fixture environment to maintain. |
| `schedule` | Creates scheduled and recurring tasks with correct timezone handling. | Recurring work outlives the conversation that set it up. |
| `work-log` | Registers work entries, tracks commits and generates daily summaries. | Standup notes and invoices that come from the record, not from memory. |

### Communication and thinking

| Skill | What it does | Why I use it |
|---|---|---|
| `brainstorm` | Four-phase collaborative brainstorming: diverge, evaluate, synthesize, refine. | Stops the model converging on the first plausible idea. |
| `email-composer` | Professional email templates in English and Spanish for common business scenarios. | Bilingual correspondence that stays consistent in register. |
| `imap-email` | Reads, searches, classifies and summarizes mail over IMAP (Gmail, Outlook, Yahoo, iCloud, custom). | Triage without handing an inbox to a third-party integration; credentials stay in env vars. |

---

## Slash commands

| Command | What it does |
|---|---|
| `/workflow <task>` | Runs the full pipeline: Planning → Check → Implementation → Check → Testing → Check → Documentation → Check → Knowledge Sync, verifying locally at each gate. |
| `/review [file]` | Triggers a code review with a type (`full`, `quick`, `security`, `performance`) and focus areas. |
| `/ollama <op>` | Local Ollama operations: list, pull, generate, embed, benchmark. |
| `/docs [query]` | Searches project documentation with scope, format and offline options. |

## Rules

`rules/python.md` and `rules/typescript.md` hold the language standards the agents are held to —
typing, project structure, error handling, testing conventions. They are referenced rather than
restated so a standard lives in exactly one place.

---

## Installation

Requires [Claude Code](https://claude.com/claude-code). The Ollama-backed parts additionally
require [Ollama](https://ollama.com) with `qwen3-coder` and `nomic-embed-text`.

```bash
git clone https://github.com/adriaalcala/claude-code-setup.git
cd claude-code-setup
```

Back up whatever you already have, then copy in the pieces you want:

```bash
cp -r agents commands hooks skills rules ~/.claude/
chmod +x ~/.claude/hooks/scripts/*.sh
```

Merge the example settings into your own `~/.claude/settings.json` (do not overwrite it blindly —
it holds your permissions):

```bash
cp examples/settings.json ~/.claude/settings.json
```

The example `settings.json` reads the Context Curator token from the environment, so export it
before starting Claude Code — or drop the `mcpServers` block if you are not running Curator:

```bash
export CURATOR_MCP_AUTH_TOKEN="your-token-here"
```

`examples/CLAUDE.md` is a template for `~/.claude/CLAUDE.md`, the user-level instruction file that
carries the anti-hallucination protocol, confidence levels and toolchain defaults.

For the browser UAT skill, install its dependencies and create a profile config:

```bash
cd ~/.claude/skills/browser-uat/scripts && npm install
cp ../configs/profiles.example.json ../configs/profiles.json
```

Then edit `profiles.json` with your own Chrome profiles and base URLs.

---

## Context Curator

Several agents and skills here assume **Context Curator**, a local code-indexing service that gives
Claude semantic search over a codebase without sending any of it to a cloud API. The service itself
is a separate project and no working code from it is included in this repository — only the
configuration that talks to it.

The shape of it:

```
Source code
  → tree-sitter parsing into semantic units (functions, classes, modules)
  → Ollama (qwen3-coder) writes a natural-language description of each unit
  → Ollama (nomic-embed-text) turns those into 768-dimensional embeddings
  → ChromaDB stores them per project, persistently
  → an MCP server exposes retrieval tools to Claude Code
```

In practice that means Claude can ask "where is authentication handled?" and get the actual relevant
functions back, rather than grepping for the word `auth`. Curator also generates `CLAUDE.md` files
from the index, so a project's conventions are derived from the code instead of hand-written and
left to rot.

Everything runs on the local machine: Ollama on `127.0.0.1:11434`, ChromaDB on `127.0.0.1:8000`, the
Curator API and its MCP server on local ports. Nothing is exposed externally, and the API is behind
a bearer token read from the environment. The privacy property is the point — indexing a client
codebase never sends a line of it anywhere.

To use this configuration without Curator, remove the `mcpServers` block from `settings.json` and
skip the `curator-admin` agent and the `context-curator-admin` skill.

---

## What is not here

Some files depend on private data and were deliberately excluded rather than sanitized:

- **`skills/browser-uat/configs/profiles.json`** — real Chrome profiles pointing at client QA and
  staging environments. A generic `profiles.example.json` is provided instead.
- **`skills/browser-uat/tests/*.json`** — recorded UAT flows against client applications, including
  their URLs and business logic.
- **`skills/browser-uat/Browser-UAT-Skill-PDE.pptx`** — an internal presentation.
- **`skills/synced/`** — plugin-synced skills that belong to third parties, including client brand
  guidelines.
- Everything else under `~/.claude/` that is state rather than configuration: session transcripts,
  logs, caches, work-log entries, backups, project histories.

Placeholders you will see in the included files: `user@example.com`, `app.example.com`,
`app-qa.example.com`, `app-staging.example.com`, `Example Corp`, `Example Client`, `/path/to/...`,
`REMOTE_HOST`, and `${CURATOR_MCP_AUTH_TOKEN}`.

---

## License

MIT — see [LICENSE](LICENSE).
