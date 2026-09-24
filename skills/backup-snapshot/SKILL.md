---
name: backup-snapshot
description: "Create git snapshots before risky operations. Tag backups with timestamp, stash changes, document recovery steps. Trigger on 'backup', 'snapshot', 'before', 'risky', 'undo', 'save state'."
---

# Backup Snapshot Skill

## Overview
Create safe restore points before dangerous operations (large refactorings, risky merges, breaking changes) using git snapshots and tags.

## Phase 1: CHECK STATUS

### Verify Clean State
```bash
git status
# No uncommitted changes should exist
# If dirty: stash or commit first
```

### Current Branch & Commits
```bash
git branch --show-current
# Current: feature/my-feature

git log -1 --oneline
# abc1234 (HEAD) feat: add new feature
```

### Remote Status
```bash
git status -sb
# On branch main, up-to-date with origin/main
```

## Phase 2: STASH OR WIP COMMIT

If uncommitted work exists, preserve it:

### Option A: Stash (temporary)
```bash
git stash push -m "WIP: [description]"
# Save current changes without committing
```

Later restore:
```bash
git stash pop
# or: git stash apply stash@{0}
```

### Option B: WIP Commit (clearer history)
```bash
git add -A
git commit -m "WIP: [description of work in progress]"
# Commit as WIP, can amend or squash later
```

## Phase 3: CREATE BACKUP TAG

Tag the current state with timestamp:

```bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
git tag -a "backup/$TIMESTAMP" -m "Backup before [operation description]"
# Example: backup/20260308-143022

# For specific branch:
git tag -a "backup/$BRANCH/$TIMESTAMP" -m "Backup of $BRANCH before risky operation"
# Example: backup/feature-x/20260308-143022
```

### Tag Naming Convention
- `backup/YYYY-MM-DD-HHMMSS` — timestamp-based
- `backup/branch-name/YYYY-MM-DD-HHMMSS` — branch-specific
- `backup/before-refactor/YYYY-MM-DD-HHMMSS` — operation-specific

## Phase 4: LOG BACKUP

Document what was backed up:

```bash
cat > BACKUP_LOG.md << EOF
# Backup Log

## Backup: backup/20260308-143022
- **Date**: $(date)
- **Branch**: $(git branch --show-current)
- **Commit**: $(git rev-parse HEAD)
- **Message**: $(git log -1 --pretty=%B)

### Reason for Backup
Backup created before [describe risky operation]

### What's included
- All committed changes
- Project state: [describe state]

### Recovery Instructions
\`\`\`bash
git checkout backup/20260308-143022
# Or reset branch to this backup:
git reset --hard backup/20260308-143022
\`\`\`

---
EOF
```

## Phase 5: RESTORE INSTRUCTIONS

Provide clear recovery steps:

### View All Backups
```bash
git tag -l "backup/*"
# Lists all backup tags
```

### View Backup Details
```bash
git show backup/20260308-143022
# Shows commit message and diff
```

### Restore to Backup
```bash
# Option 1: Checkout backup (detached HEAD)
git checkout backup/20260308-143022

# Option 2: Reset current branch to backup (DESTRUCTIVE)
git reset --hard backup/20260308-143022

# Option 3: Create new branch from backup
git checkout -b restore-20260308 backup/20260308-143022
```

### Restore Specific File
```bash
# Get file as it was at backup
git show backup/20260308-143022:path/to/file.py > file.py
```

## Phase 6: LIST SNAPSHOTS

Show existing backups:

### List All Backups
```bash
git tag -l "backup/*" -n --sort=-version:refname
# Output:
# backup/20260308-143022     Backup before large refactoring
# backup/feature-x/20260308-141500  Backup of feature-x branch
# backup/20260307-160000     Backup before risky merge
```

### Show Recent Backups
```bash
git tag -l "backup/*" -n --sort=-version:refname | head -10
```

### Cleanup Old Backups
```bash
# Keep recent 10, delete older ones
git tag -l "backup/*" --sort=-version:refname | tail -n +11 | xargs -r git tag -d
```

## Phase 7: OPERATIONS WORKFLOW

### Large Refactoring
```bash
# 1. Create backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
git tag -a "backup/before-refactor-$TIMESTAMP" -m "Before large refactoring"

# 2. Perform refactoring

# 3. Test thoroughly
pytest tests/

# 4. If something breaks, restore:
git reset --hard backup/before-refactor-$TIMESTAMP
# Then retry with different approach
```

### Risky Merge
```bash
# Backup both branches
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
git tag -a "backup/before-merge-$TIMESTAMP" -m "Before merging develop into main"

# Perform merge
git merge develop

# If conflicts or issues, restore:
git reset --hard backup/before-merge-$TIMESTAMP
# Then resolve conflicts before retrying
```

### Breaking API Change
```bash
# Backup before changes
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
git tag -a "backup/api-v2-$TIMESTAMP" -m "Before API v2 breaking changes"

# Make breaking changes
# Run tests
uv run pytest

# If tests fail and unfixable, revert:
git reset --hard backup/api-v2-$TIMESTAMP
```

### Major Dependency Update
```bash
# Before updating critical dependency
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
git tag -a "backup/before-upgrade-$TIMESTAMP" -m "Before upgrading FastAPI from v0.100 to v1.0"

# Update dependency
uv add fastapi@latest

# Run full test suite
uv run pytest --cov

# If major issues:
git reset --hard backup/before-upgrade-$TIMESTAMP
# Revert, then update incrementally
```

## Phase 8: BEST PRACTICES

### When to Create Backups
- ✓ Large refactorings (>50 files changed)
- ✓ Risky merges (long-lived branches)
- ✓ Breaking changes (API, dependencies)
- ✓ Experimental features (uncertain outcome)
- ✓ Before database migrations
- ✗ Small bug fixes (use git revert instead)
- ✗ Regular commits (not needed, git history is backup)

### Tag Naming
- Use clear, descriptive names
- Include operation type: `backup/before-[operation]`
- Include timestamp: `YYYYMMDD-HHMMSS`
- Keep under 50 characters

### Documentation
- Log why backup was created
- Keep BACKUP_LOG.md updated
- Include recovery instructions

### Cleanup
- Backups take disk space
- Delete old backups after 1 month
- Keep only recent 5-10 per operation type

### Share Across Team
```bash
# Push backups to remote so team can access
git push origin "refs/tags/backup/*"

# Only backups, not all tags:
git push origin "refs/tags/backup/*:refs/tags/backup/*"
```

## Example Backup Workflow

```bash
# Step 1: Prepare
git status  # Must be clean
# Branch: main, all changes committed

# Step 2: Create backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
git tag -a "backup/refactor-parser-$TIMESTAMP" \
  -m "Backup before refactoring parser module"

# Step 3: Perform risky operation
# ... make changes, refactor code ...

# Step 4: Test
pytest tests/ -v

# Step 5a: Success? Commit and delete backup
git commit -am "refactor: simplify parser module"
git tag -d "backup/refactor-parser-$TIMESTAMP"

# Step 5b: Failure? Restore from backup
git reset --hard "backup/refactor-parser-$TIMESTAMP"
# Then try different approach
```

