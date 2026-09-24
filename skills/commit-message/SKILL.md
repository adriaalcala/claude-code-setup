---
name: "Conventional Commits Workflow"
description: "Write semantic commit messages following conventional commits specification"
allowed-tools:
  - Read
  - Bash
  - Grep
preferred-model: "opus"
---

# Conventional Commits Workflow

Write clear, semantic commit messages that enable automated changelog generation and version management.

## Specification Overview

**Format:**
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Commit Types

### 1. `feat` - Feature
New functionality or capability added.

```
feat(auth): add JWT token refresh mechanism

Implement automatic token refresh on expiration.
Tokens are refreshed on any API request within 5 minutes
of expiration.

Closes #123
```

**When to use:**
- Adding new API endpoint
- Adding new command/CLI option
- Adding new configuration option
- Adding new library/dependency

### 2. `fix` - Bug Fix
Corrects a bug or broken functionality.

```
fix(api): prevent duplicate user creation on concurrent requests

Added mutex lock around user creation to prevent race conditions
that could result in duplicate email entries despite unique constraint.

Fixes #456
```

**When to use:**
- Fixing a bug report
- Fixing broken tests
- Fixing incorrect behavior
- Handling edge cases

### 3. `docs` - Documentation
Changes documentation, comments, or docstrings.

```
docs: update API endpoint documentation

Added examples and response schemas for all user endpoints.
Clarified pagination behavior and error codes.
```

**When to use:**
- Writing docstrings
- Updating README
- Adding code comments
- Updating API documentation
- Writing architecture guides

### 4. `style` - Code Style
Non-functional changes: formatting, whitespace, quotes, etc. (NOT linting fixes).

```
style: reformat code to 88 characters per Black standard
```

**When to use:**
- Manual reformatting (automated linting is different)
- Whitespace changes
- Consistent naming/quoting

### 5. `refactor` - Refactoring
Code reorganization without changing behavior or adding features.

```
refactor(auth): extract token validation into utility function

Moved token validation logic into reusable function to reduce
duplication between middleware and service layer.
```

**When to use:**
- Extracting functions
- Renaming variables
- Reorganizing code structure
- Improving readability

### 6. `perf` - Performance
Improves performance or efficiency.

```
perf(db): add index on user emails for faster lookups

Added database index on users.email column. Query performance
improved from 200ms to 5ms on average.
```

**When to use:**
- Adding indexes
- Optimizing queries
- Reducing memory usage
- Improving algorithm complexity

### 7. `test` - Testing
Add, update, or fix tests (no production code changes).

```
test(auth): add comprehensive JWT validation tests

Added 15 new test cases covering token expiration,
invalid signatures, and malformed tokens.
```

**When to use:**
- Adding unit tests
- Adding integration tests
- Adding E2E tests
- Fixing test infrastructure

### 8. `ci` - CI/CD
Changes to CI/CD configuration and scripts.

```
ci: add Python 3.12 to test matrix

Updated GitHub Actions workflow to test against Python 3.12
in addition to 3.9, 3.10, and 3.11.
```

**When to use:**
- Updating GitHub Actions
- Updating Docker configs
- Updating build scripts
- Updating deployment configs

### 9. `chore` - Chores
Miscellaneous changes: dependencies, build tools, etc.

```
chore: upgrade dependencies

Updated project dependencies to latest versions:
- fastapi 0.104.0 → 0.108.0
- sqlalchemy 2.0.20 → 2.0.24
- pydantic 2.4.0 → 2.5.0
```

**When to use:**
- Dependency updates
- Package upgrades
- Removing dead code
- Cleaning up build artifacts

## Message Structure

### Description (Required)

**Rules:**
- Use imperative mood ("add", not "added" or "adds")
- Don't capitalize first letter
- No period (.) at the end
- Keep under 50 characters if possible
- Be specific and descriptive

**Good:**
```
feat(api): add rate limiting to auth endpoints
fix(db): handle null user preferences gracefully
docs: document environment variable configuration
perf(cache): implement Redis caching layer
```

**Bad:**
```
feat(api): Updates.
fix(db): Bug fix.
docs: Documenting.
perf(cache): Lots of improvements.
```

### Scope (Optional)

**Specifies what part of the codebase is affected.**

Examples:
```
feat(auth): ...
fix(database): ...
refactor(api): ...
test(utils): ...
docs(readme): ...
ci(github-actions): ...
```

**Common scopes:**
- `api`, `auth`, `database`, `cache`, `queue`
- `cli`, `config`, `logging`, `middleware`
- `utils`, `types`, `models`, `tests`
- `docker`, `helm`, `terraform`

### Body (Optional)

**Explains the motivation and details.**

Rules:
- Wrap at 72 characters
- Explain WHAT and WHY, not HOW
- Separate from description with blank line
- Use past tense ("changed", "added")

**Good body:**
```
Implement automatic token refresh on expiration to improve
user experience. Previously users would be logged out without
warning when tokens expired. Now tokens are automatically
refreshed on any API request within 5 minutes of expiration,
preventing disruptive logouts.

The refresh is transparent to the client and doesn't require
explicit token management.
```

**Bad body:**
```
Fixed the thing. It was broken. Now it works better.
```

### Footer (Optional)

**References issues, breaking changes, or metadata.**

**Pattern 1: Issue reference**
```
Closes #123
Fixes #456
Resolves #789
Related to #999
```

**Pattern 2: Breaking changes**
```
BREAKING CHANGE: Environment variable DB_HOST changed to DATABASE_URL
(see migration guide in docs/MIGRATION.md)
```

**Pattern 3: Multiple footers**
```
Closes #123
Reviewed-by: Alice <alice@example.com>
Co-Authored-By: Bob <bob@example.com>
```

## Full Examples

### Example 1: Feature with Body and Footer
```
feat(auth): implement OAuth2 authorization flow

Add support for OAuth2 authorization code flow to enable
third-party integrations. Users can now authorize external
applications to access their data with scoped permissions.

Implementation includes:
- New /oauth/authorize endpoint
- Token exchange mechanism
- Scope validation and enforcement
- Refresh token support

Closes #234
```

### Example 2: Bug Fix with Context
```
fix(api): prevent race condition in user registration

Add mutex lock around user creation step to prevent duplicate
users when multiple concurrent requests use the same email.
Previously, the unique constraint check could be bypassed by
concurrent requests arriving before the constraint check.

The email uniqueness is now enforced at the application level
with a lock, preventing duplicates from reaching the database.

Fixes #567
```

### Example 3: Refactoring
```
refactor(database): extract common query logic into base repository

Move common CRUD operations from individual repositories into
BaseRepository abstract class. Reduces duplication across
UserRepository, ProductRepository, and OrderRepository.

No functional changes. All tests pass.
```

### Example 4: Documentation
```
docs: add quick start guide and API examples

Created docs/QUICKSTART.md with:
- Installation instructions
- Basic setup
- First API call example

Updated README.md with architecture overview and links to
detailed documentation.
```

### Example 5: Breaking Change
```
feat(api): restructure error response format

Change error response format from:
  {"error": "message", "code": 400}
to:
  {"success": false, "error": {"code": "VALIDATION_ERROR", "message": "..."}}

This aligns errors with our success response format and enables
better error categorization on the client.

BREAKING CHANGE: Error response format changed. See
migration guide in docs/MIGRATION_v2.md for client updates.

Closes #890
```

## Workflow Integration

### In Git Hooks

```bash
# .git/hooks/prepare-commit-msg
#!/bin/bash

# Auto-add JIRA ticket if in branch name
branch=$(git rev-parse --abbrev-ref HEAD)
if [[ $branch =~ ([A-Z]+-[0-9]+) ]]; then
    ticket="${BASH_REMATCH[1]}"
    sed -i "1s/^/${ticket}: /" "$1"
fi
```

### Commit Message Template

```
# Create .git/info/commit-template
<type>(<scope>): <description>

# Example:
# feat(auth): add OAuth2 support

# Types:
#   feat:     A new feature
#   fix:      A bug fix
#   docs:     Documentation changes
#   style:    Code style changes (not linting)
#   refactor: Code refactoring
#   perf:     Performance improvements
#   test:     Test additions/changes
#   ci:       CI/CD changes
#   chore:    Dependency updates, cleanup

# Scope examples:
#   auth, api, database, cache, config, cli

# Guidelines:
#   - Use imperative mood ("add", not "added")
#   - Don't capitalize first letter
#   - No period at the end
#   - Keep description under 50 characters

# Add footer for issue reference:
# Closes #123
# BREAKING CHANGE: description

# Configure with:
# git config commit.template .git/info/commit-template
```

### Changelog Generation

Commits following conventional commits enable automated changelog:

```bash
# Using commitizen
commitizen changelog

# Using conventional-changelog
conventional-changelog -p angular -i CHANGELOG.md -s

# Manual parsing for Python
import re
commits = get_commits_since_last_tag()
for commit in commits:
    if commit.startswith("feat"):
        print(f"### Features\n- {extract_description(commit)}")
    elif commit.startswith("fix"):
        print(f"### Bug Fixes\n- {extract_description(commit)}")
```

## Version Management with Semver

Conventional commits map to semantic versioning:

```
feat() → MINOR version (1.0.0 → 1.1.0)
fix()  → PATCH version (1.0.0 → 1.0.1)
BREAKING CHANGE footer → MAJOR version (1.0.0 → 2.0.0)
```

## Commit Checklist

Before committing, verify:

```
□ Type is one of: feat, fix, docs, style, refactor, perf, test, ci, chore
□ Scope (if needed) is relevant to changes
□ Description is imperative mood and under 50 chars
□ Description doesn't end with period
□ Body (if included) explains WHY, not HOW
□ Footer includes issue reference (Closes #123)
□ No multiple concerns in one commit
□ Tests pass
□ Code follows project style
```

## Anti-Patterns

**Avoid:**
```
✗ SUPER LONG DESCRIPTIONS THAT TRY TO SAY EVERYTHING IN ONE LINE
✗ Fixed bugs and added features and updated docs all at once
✗ vague descriptions like "stuff" or "things" or "updated"
✗ Commit messages in non-English (use English for consistency)
✗ Mixing concerns (fix + refactor + chore in one commit)
```

**Prefer:**
```
✓ Clear, focused commit with single responsibility
✓ Atomic commits (each commit is deployable)
✓ Descriptive but concise messages
✓ English, consistent with team
✓ Related changes in single commit (same file + test)
```

## Tips

1. **Commit early and often** - Smaller commits are easier to review
2. **One concern per commit** - Makes history cleaner
3. **Write for the future** - Others will read these messages
4. **Use footers liberally** - Links to tickets, related commits, breaking changes
5. **Be consistent** - Your team will thank you

## Resources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Angular Commit Guidelines](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#-commit-message-guidelines)
- [Commitizen](http://commitizen.github.io/cz-cli/)
