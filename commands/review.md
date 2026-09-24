# Code Review Command

Quick-access command for triggering code reviews.

## Usage

```bash
/review [file] [options]
```

## Options

- `--file <path>`: File to review (required if not specified as argument)
- `--type <type>`: Review type: full, quick, security, performance (default: full)
- `--focus <area>`: Focus area: correctness, design, testing, style (multiple allowed)
- `--verbose`: Show detailed output
- `--json`: Output as JSON

## Examples

### Quick File Review
```bash
/review src/services/user_service.py
```

### Security-Focused Review
```bash
/review src/api/routes/users.py --type security
```

### Multi-Focus Review
```bash
/review src/models/database.py --focus correctness --focus security
```

### JSON Output
```bash
/review src/app.py --type full --json
```

### Verbose Review
```bash
/review src/utils/validators.py --verbose
```

## Review Types

### full (default)
Comprehensive review covering all 6 points:
- Correctness
- Performance
- Security
- Design & Architecture
- Testing
- Style & Maintainability

### quick
Fast review (5-10 minutes) covering:
- Critical correctness issues
- Obvious security problems
- Performance red flags

### security
Focused security review:
- SQL injection vulnerabilities
- XSS vulnerabilities
- Authentication/authorization issues
- Data exposure risks
- Input validation

### performance
Performance-focused review:
- Algorithm efficiency
- Database query optimization
- Memory management
- Caching opportunities
- Concurrency issues

## Output

### Standard Output
```
Code Review: src/services/user_service.py
===============================================

OVERALL RATING: PASS_WITH_COMMENTS
Reviewed at: 2026-03-08T14:32:15Z

ISSUES FOUND: 2
├── HIGH: Missing null check (line 45)
└── MEDIUM: Duplicate code (lines 23-28)

SUMMARY
✓ Correctness: PASS
✓ Performance: PASS
! Security: PASS_WITH_COMMENTS (1 issue)
✓ Design: PASS
! Testing: PASS_WITH_COMMENTS (1 issue)
✓ Style: PASS

RECOMMENDATIONS
1. Add null safety check before accessing user.email
2. Extract validation logic to separate method

Ready to merge with suggested improvements.
```

### JSON Output
```json
{
  "file": "src/services/user_service.py",
  "timestamp": "2026-03-08T14:32:15Z",
  "type": "full",
  "rating": "PASS_WITH_COMMENTS",
  "scores": {
    "correctness": 9,
    "performance": 8,
    "security": 8,
    "design": 9,
    "testing": 7,
    "style": 9
  },
  "issues": [
    {
      "severity": "HIGH",
      "category": "CORRECTNESS",
      "line": 45,
      "description": "Missing null check before accessing user.email",
      "suggestion": "Add: if user is not None before accessing properties"
    }
  ]
}
```

## Integration Points

### Pre-Commit Hook
```bash
# In .git/hooks/pre-commit
/review $(git diff --cached --name-only) --type quick
```

### CI/CD Pipeline
```yaml
- name: Code Review
  run: /review ${{ github.event.pull_request.changed_files }} --type full
```

### IDE Integration
Configure in your editor to run review on save or with keyboard shortcut.

## Performance

- **Quick review:** 2-5 minutes
- **Full review:** 5-15 minutes
- **Security review:** 3-8 minutes
- **Performance review:** 3-8 minutes

For large files (>500 lines), time increases proportionally.

## Tips

1. **Review related changes together** - More context helps accuracy
2. **Use quick reviews for iterative development** - Full reviews for final PR
3. **Focus security reviews on API/auth code** - Highest risk areas
4. **Performance reviews for loops and queries** - Most likely bottlenecks
5. **Check JSON output programmatically** - Integrate into workflows

## Exit Codes

- `0`: No issues found (PASS)
- `1`: Comments only (PASS_WITH_COMMENTS)
- `2`: Issues found, review recommended (NEEDS_REVIEW)
- `3`: Critical issues, must fix before merge (CRITICAL)
- `4`: Error during review (ERROR)

## Related Commands

- `/docs` - Documentation search
- `/commit` - Conventional commits workflow
- `/test` - Run tests
