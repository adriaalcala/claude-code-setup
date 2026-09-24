---
name: Work Log
description: Register work entries, track commits, and generate daily summaries
model: sonnet
tools:
  - Read
  - Write
  - Bash
  - Glob
triggers:
  - "register this"
  - "registra això"
  - "log this work"
  - "save work"
  - "daily summary"
  - "resum diari"
  - "work summary"
  - "what did I do today"
  - "què he fet avui"
keywords:
  - work
  - log
  - register
  - summary
  - daily
  - tracking
---

# Work Log Skill

Track and register work done during coding sessions. Supports manual registration, automatic commit tracking, and daily summaries.

## Storage

Work entries are stored in `~/.claude/work-log/` with daily JSON files:

```
~/.claude/work-log/
├── 2025-03-15.json
├── 2025-03-16.json
└── ...
```

### Entry Format

```json
{
  "entries": [
    {
      "timestamp": "2025-03-16T10:30:00",
      "type": "manual|commit|session",
      "project": "/path/to/project",
      "description": "What was done",
      "files": ["file1.py", "file2.ts"],
      "commit": {
        "hash": "abc123",
        "message": "feat: add feature"
      },
      "tags": ["feature", "api"],
      "duration_minutes": 45
    }
  ]
}
```

## Modes of Operation

### 1. Manual Registration (Trigger: "register this", "registra això")

When the user says "register this" or similar:

1. **Analyze the current session context:**
   - What files were read/modified?
   - What was the main task accomplished?
   - What project directory is active?

2. **Extract work details:**
   ```bash
   # Get current working directory
   pwd

   # Check recent git activity if in a repo
   git log --oneline -5 2>/dev/null || echo "Not a git repo"
   git diff --stat HEAD~1 2>/dev/null || true
   ```

3. **Create entry with:**
   - Timestamp (current time)
   - Type: "manual"
   - Project path
   - Description (summarize from session context)
   - Files modified (from git or session tracking)
   - Tags (infer from file types/task nature)

4. **Append to today's log file**

### 2. Commit-Triggered Registration (Hook-based)

When invoked after a git commit (via hook):

1. **Extract commit info:**
   ```bash
   git log -1 --pretty=format:'{"hash":"%h","message":"%s","author":"%an","date":"%ai"}'
   git diff --stat HEAD~1 --name-only
   ```

2. **Create entry with:**
   - Type: "commit"
   - Commit hash and message
   - Files changed in commit
   - Project from git root

3. **Append to today's log**

### 3. Daily Summary (Trigger: "daily summary", "resum diari")

When the user asks for a summary:

1. **Read today's log file:**
   ```bash
   cat ~/.claude/work-log/$(date +%Y-%m-%d).json 2>/dev/null
   ```

2. **Generate summary including:**
   - Total entries
   - Projects worked on
   - Total commits
   - Key accomplishments (from descriptions)
   - Files touched
   - Time breakdown by project
   - Tag distribution

3. **Format output as markdown:**

   ```markdown
   ## Daily Work Summary - 2025-03-16

   ### Overview
   - **Total entries:** 8
   - **Projects:** 3
   - **Commits:** 5

   ### Projects

   #### project-name (4 entries)
   - feat: add user authentication (commit)
   - Implemented JWT validation (manual)
   - fix: resolve token expiry bug (commit)

   ### Tags
   - #feature: 3
   - #bugfix: 2
   - #api: 4

   ### Files Modified
   - src/auth/*.py (5 files)
   - tests/test_auth.py
   ```

### 4. Weekly/Monthly Summary (Trigger: "weekly summary", "monthly summary")

Aggregate multiple daily logs for broader view.

## Implementation

### Reading/Writing Log Files

```python
import json
from pathlib import Path
from datetime import datetime

LOG_DIR = Path.home() / ".claude" / "work-log"
LOG_DIR.mkdir(parents=True, exist_ok=True)

def get_today_file():
    return LOG_DIR / f"{datetime.now().strftime('%Y-%m-%d')}.json"

def load_entries(date_str=None):
    if date_str is None:
        date_str = datetime.now().strftime('%Y-%m-%d')
    log_file = LOG_DIR / f"{date_str}.json"
    if log_file.exists():
        return json.loads(log_file.read_text())
    return {"entries": []}

def save_entry(entry):
    log_file = get_today_file()
    data = load_entries()
    data["entries"].append(entry)
    log_file.write_text(json.dumps(data, indent=2, ensure_ascii=False))
```

### Workflow

#### For Manual Registration:

1. Check context for what was done
2. Run git commands if in repo
3. Construct entry JSON
4. Append to log file
5. Confirm to user what was logged

#### For Daily Summary:

1. Read today's log file
2. Parse and aggregate entries
3. Generate markdown summary
4. Display to user

## Example Interactions

### Register Work
```
User: "register this - implemented the new API endpoints"

Action:
1. Get current directory and git status
2. Create entry:
   {
     "timestamp": "2025-03-16T14:30:00",
     "type": "manual",
     "project": "/path/to/projects/my-api",
     "description": "Implemented the new API endpoints",
     "files": ["src/routes/users.py", "src/routes/items.py"],
     "tags": ["api", "feature"]
   }
3. Save to ~/.claude/work-log/2025-03-16.json
4. Reply: "Registered: Implemented the new API endpoints (2 files)"
```

### Daily Summary
```
User: "daily summary"

Action:
1. Read ~/.claude/work-log/2025-03-16.json
2. Generate and display summary
```

### Automatic Commit Hook
```
Hook triggers after: git commit

Action:
1. Extract commit info
2. Create entry with type: "commit"
3. Append to log
```

## Hook Configuration

To enable automatic logging on git commits, add this to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/scripts/work-log-commit.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

## Commands Reference

| Trigger | Action |
|---------|--------|
| `register this` | Log current work manually |
| `registra això` | Log current work (Catalan) |
| `daily summary` | Show today's work summary |
| `resum diari` | Today's summary (Catalan) |
| `weekly summary` | Show this week's summary |
| `what did I do today` | Alias for daily summary |

## Tags Auto-Detection

Tags are inferred from:
- File extensions: `.py` → #python, `.ts` → #typescript
- Commit prefixes: `feat:` → #feature, `fix:` → #bugfix
- Directory names: `/api/` → #api, `/tests/` → #testing
- User-provided: "register this #urgent #frontend"