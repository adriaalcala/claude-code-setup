---
name: git-detective
description: "Investigate git history to understand why code exists, who changed it, and when. Use for git archaeology: blame, log, bisect, finding commits by message/content, tracing file renames. Trigger on 'why is this code like this?', 'who changed this?', 'when was this introduced?', 'find the commit that broke X'."
---

# Git Detective Skill

## Overview
Deep-dive into git history to understand code provenance, trace changes, and answer "why?" questions about the codebase.

## Phase 1: ASSESS
Understand what the user wants to know:
- **Why code exists**: rationale, original author intent
- **Who changed it**: commit authors, review history
- **When it was introduced**: timeline, release context
- **What broke**: bisect, regression identification
- **File/feature history**: lineage, renames, deletions

Clarify scope: single file, function, feature, time range, or branch.

## Phase 2: INVESTIGATE
Git commands toolkit:

### Commit Search
- `git log --all --grep="keyword"` — find commits by message substring
- `git log --all --grep="keyword" -i` — case-insensitive search
- `git log --all --author="name"` — commits by author

### Content Search (Pickaxe)
- `git log -S "code_string" --all` — find when string added/removed
- `git log -S "code_string" -p --all` — with diffs
- `git log -G "regex_pattern" --all` — find commits where regex matched diff

### Line Attribution
- `git blame -L start,end file` — annotate lines with commits
- `git blame -L start,end -C file` — detect copy/move
- `git blame --show-stats file` — summary of blame

### File History & Renames
- `git log --follow -- file` — history including renames
- `git log --diff-filter=D -- "*/filename"` — find deleted files
- `git show <hash>:path/to/file` — content at specific commit
- `git log -p -- file` — full diff history of file

### Binary Search (Bisect)
- `git bisect start` — begin bisect
- `git bisect bad HEAD` — mark current as broken
- `git bisect good <hash>` — mark known-good commit
- `git bisect bad/good` — iterate
- `git bisect log` — view history
- `git bisect reset` — exit bisect

### Statistics & Patterns
- `git shortlog -sn -- path/` — contribution stats by author
- `git log --oneline --graph --all` — full history graph
- `git log --date=short --format='%h %ad %an %s' -- file` — timeline

### Complex Queries
- `git log --all --since="2024-01-01" --until="2024-12-31"` — date range
- `git log --all -S "code" -- path/to/file` — content in specific path
- `git log --all --grep="^feat:" --grep="^fix:"` — conventional commits

## Phase 3: ANALYZE
Connect findings and explain the story:
- **Timeline**: When was code added, modified, removed?
- **Authorship**: Who wrote original code? Who modified it? Why?
- **Rationale**: Commit messages, PR context, issue references
- **Impact**: What depended on this change? What downstream effects?
- **Regression pattern**: If bisect reveals breakage, what changed?

## Phase 4: REPORT
Narrative report with:
1. **Question restated** — What we're investigating
2. **Key findings** — Timeline of relevant commits with hashes, authors, dates
3. **Commit details** — Full messages, diffs for top 3-5 commits
4. **Root cause** — Why the code is as it is
5. **Affected areas** — Related files, features, deployments
6. **Recommendations** — Next steps if needed

Format as markdown with commit hashes as `[abc1234](link)` if in GitHub.

## Local-First: Ollama Integration
For large diffs or complex code changes:
1. Extract the diff or code snippet from git
2. Feed to `ollama run qwen3-coder "Analyze this diff and explain the intent: [CODE]"`
3. Use output to contextualize findings in the narrative
4. Summarize complex changes without cloud API calls

This keeps sensitive code history local while leveraging fast local analysis.

## Example Workflows

### "Who broke the login?"
```bash
git bisect start
git bisect bad HEAD
git bisect good <known-good-commit>
# ... iterate until found
git show <bad-commit>
```

### "When was this feature added?"
```bash
git log --all -S "feature_flag_name" -- src/
git show <hash>
```

### "Why does this class look like this?"
```bash
git blame -L1,100 src/MyClass.ts
git log --follow -- src/MyClass.ts
# Then for each major refactor:
git show <hash> | head -50
```

### "Find all references to a deleted module"
```bash
git log --all --diff-filter=D -- "src/old-module/**"
git show <deletion-commit>
```

