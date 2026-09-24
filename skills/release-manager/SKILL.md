---
name: release-manager
description: "Manage releases: semantic versioning from conventional commits, changelog generation, git tags, release notes. Trigger on 'release', 'version bump', 'changelog', 'tag', 'cut a release', 'prepare release'."
---

# Release Manager Skill

## Overview
Automate release management: calculate semantic version, generate changelogs, create tags, and draft release notes using conventional commits.

## Phase 1: ANALYZE
Examine git history since last tag:

### Find Last Release
```bash
git describe --tags --abbrev=0
# or: git tag -l | sort -V | tail -1
```

If no tags exist, start from first commit.

### Get Commits Since Last Release
```bash
git log <last-tag>..HEAD --oneline --no-decorate
# or from start:
git log --oneline --no-decorate
```

### Extract Conventional Commit Types
Parse commit messages for conventional commit format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- **feat**: new feature (MINOR version bump)
- **fix**: bug fix (PATCH version bump)
- **perf**: performance improvement (PATCH)
- **refactor**: code refactoring (PATCH, no version bump unless noted)
- **docs**: documentation only (no version bump)
- **style**: formatting only (no version bump)
- **test**: tests only (no version bump)
- **chore**: dependency updates, build (no version bump)
- **ci**: CI/CD changes (no version bump)

Breaking Changes:
- Footer `BREAKING CHANGE: ...` (MAJOR version bump)
- Exclamation in type: `feat!: ...` (MAJOR version bump)

### Classify Commits
```
feat commits: count = MINOR_COUNT
fix commits: count = PATCH_COUNT
BREAKING CHANGE: count = BREAKING_COUNT
```

## Phase 2: VERSION
Calculate next semantic version:

### Read Current Version
- Python: `grep -oP '(?<=version = ")[^"]*' pyproject.toml`
- Node: `grep version package.json | head -1`
- Tags: `git tag -l | sort -V | tail -1`

Current version format: `x.y.z` (major.minor.patch)

### Calculate Next Version
If BREAKING_COUNT > 0:
  next = (major+1).0.0

Else if MINOR_COUNT > 0:
  next = major.(minor+1).0

Else if PATCH_COUNT > 0:
  next = major.minor.(patch+1)

Else:
  next = major.minor.patch (no change)

### Validate Semver
Check version is valid: `^[0-9]+\.[0-9]+\.[0-9]+$` (and optional pre-release/build)

## Phase 3: CHANGELOG
Generate changelog entry with structured sections:

### Structure
```
## [x.y.z] - YYYY-MM-DD

### Added
- New feature 1 (commit hash)
- New feature 2 (commit hash)

### Fixed
- Bug fix 1 (commit hash)
- Bug fix 2 (commit hash)

### Changed
- Improvement 1 (commit hash)
- Refactoring 1 (commit hash)

### Breaking Changes
- BREAKING: Old API removed, use new API instead (commit hash)
```

### Generate from Commits
1. Iterate commits since last tag
2. Group by type (Added/Fixed/Changed/Breaking)
3. Extract subject line + commit hash
4. Create readable bullet points
5. Include author if first-time contributor

### Append to CHANGELOG.md
- Insert new version at top (after header)
- Keep old versions below
- Validate markdown syntax

## Phase 4: EXECUTE (with approval)
Only proceed after user reviews and approves version and changelog.

### Update Version Files
- Python: `sed -i 's/version = ".*"/version = "x.y.z"/' pyproject.toml`
- Node: `npm version x.y.z --no-git-tag-version` or edit package.json
- Other: update version field in relevant file

### Update CHANGELOG.md
Append entry created in Phase 3

### Create Git Tag
```bash
git add pyproject.toml CHANGELOG.md  # (or equivalent)
git commit -m "chore: release v<x.y.z>"
git tag -a v<x.y.z> -m "Release <x.y.z>

[Insert changelog entry here]"
```

### Draft Release Notes
Create markdown file `RELEASE_NOTES_<x.y.z>.md`:
- Release title: "Release v<x.y.z> - <date>"
- Changelog excerpt
- Migration guide (if BREAKING changes)
- Contributors list (from shortlog)
- Installation/upgrade instructions
- Known issues (if any)

### Example
```
# Release v2.5.0 - 2026-03-08

## Summary
Added new API endpoints for batch operations. Fixed critical memory leak in cache layer.

## What's New

### Added
- Batch processing API with `/api/v2/batch` endpoint
- Webhook support for async notifications
- Admin dashboard metrics panel

### Fixed
- Memory leak in Redis cache causing 100% heap growth
- Race condition in concurrent write operations
- SQL injection vulnerability in legacy search

### Breaking Changes
- Removed deprecated `/api/v1/users` endpoint (use `/api/v2/users` instead)
- Changed auth header from `X-API-Key` to `Authorization: Bearer token`

## Migration Guide
If using v1 API, update endpoints in your client:
- OLD: `GET /api/v1/users` → NEW: `GET /api/v2/users`
- OLD: Header `X-API-Key: key` → NEW: Header `Authorization: Bearer key`

## Contributors
- Alice Smith (5 commits)
- Bob Johnson (3 commits)
- Carol Davis (1 commit, first-time)

## Install/Upgrade
```bash
pip install myproject==2.5.0
# or
npm install myproject@2.5.0
```

## Known Issues
- Batch API rate limit: 100 requests/minute (will increase in 2.5.1)
- Dashboard slow with >10k metrics (optimization in progress)
```

## Dry-Run Mode (Default)
Always run in dry-run first:
```bash
release-manager --dry-run --version 2.5.0
# Output: would update pyproject.toml, CHANGELOG.md, create tag v2.5.0
# No actual changes made
```

Then ask user: "Ready to proceed with release v2.5.0? (y/n)"

## List Previous Releases
```bash
git tag -l -n5 --sort=-version:refname | head -20
```

Shows previous versions with tag messages for reference.

