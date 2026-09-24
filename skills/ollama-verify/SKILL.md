---
name: "Ollama Code Verification"
description: "Use local Ollama models to verify code, review implementations, analyze patterns"
allowed-tools:
  - Bash
  - Read
  - Grep
preferred-model: "opus"
---

# Ollama Code Verification

Use Ollama with qwen3-coder for local code analysis and verification. No external API calls - everything runs on the server.

## Quick Start

**Check Ollama status:**
```bash
curl -s http://127.0.0.1:11434/api/tags | jq .
```

**Verify code locally:**
```bash
ollama run qwen3-coder "Verify this Python code for syntax errors and best practices:
\`\`\`python
async def fetch_data(url: str) -> dict:
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as resp:
            return await resp.json()
\`\`\`"
```

## Ollama Models Available

- **qwen3-coder**: Large language model for code analysis, review, patterns (primary)
- **nomic-embed-text**: Text embedding for semantic search and similarity (secondary)

## Verification Use Cases

### 1. Code Syntax Verification

**Verify Python code for syntax errors and basic correctness:**

```bash
ollama run qwen3-coder "TASK: Verify Python code correctness

CODE:
\`\`\`python
class User:
    def __init__(self, name: str, email: str):
        self.name = name
        self.email = email

    def validate_email(self):
        return '@' in self.email

async def get_users(db_session):
    users = await db_session.execute(
        select(User).where(User.status == 'active')
    )
    return users.scalars().all()
\`\`\`

VERIFICATION CHECKLIST:
1. Syntax errors?
2. Type hints correct?
3. Async/await proper?
4. Database query correct?
5. Security issues?

RESPOND: PASS/FAIL with specific findings"
```

### 2. API Design Review

**Verify REST API design follows conventions:**

```bash
ollama run qwen3-coder "TASK: Review REST API design

ENDPOINTS:
1. GET /api/users (list all users)
   Response: {\"users\": [{\"id\": 1, \"name\": \"Alice\"}]}

2. POST /api/users (create user)
   Request: {\"name\": \"Bob\", \"email\": \"bob@example.com\"}
   Response: {\"id\": 2, \"name\": \"Bob\", \"email\": \"bob@example.com\"}

3. PUT /api/users/{id} (update user)
   Request: {\"name\": \"Bob Updated\"}
   Response: {\"id\": 2, \"name\": \"Bob Updated\"}

4. DELETE /api/users/{id} (delete user)
   Response: {\"status\": \"deleted\"}

CHECKS:
1. HTTP methods correct for operations?
2. Status codes appropriate?
3. Request/response structure consistent?
4. Naming follows REST conventions?
5. Any security concerns?

RESPOND: PASS/FAIL with specific recommendations"
```

### 3. Implementation Pattern Review

**Check if implementation follows best practices:**

```bash
ollama run qwen3-coder "TASK: Review implementation pattern

IMPLEMENTATION:
\`\`\`python
# Database query
def get_active_users(limit=10):
    return db.session.query(User).filter(
        User.status == 'active'
    ).limit(limit).all()

# Service function
def create_user(email, name):
    user = User(email=email, name=name)
    db.session.add(user)
    db.session.commit()
    return user

# API endpoint
@app.route('/users', methods=['GET'])
def list_users():
    users = get_active_users()
    return {
        'users': [{'id': u.id, 'name': u.name} for u in users]
    }
\`\`\`

PATTERN CHECKS:
1. Database access pattern (should be async?)?
2. Transaction handling correct?
3. Error handling present?
4. Separation of concerns good?
5. Testability adequate?

RESPOND: PASS/FAIL with improvement suggestions"
```

### 4. Security Pattern Analysis

**Check code for common security issues:**

```bash
ollama run qwen3-coder "TASK: Security code review

CODE:
\`\`\`python
@app.route('/api/data/<id>', methods=['GET'])
def get_data(id):
    # SQL query with user input
    query = f\"SELECT * FROM data WHERE id = {id}\"
    result = db.execute(query)
    return result.to_dict()

@app.route('/api/upload', methods=['POST'])
def upload_file():
    file = request.files['file']
    # Save to server with original filename
    file.save(f'/uploads/{file.filename}')
    return {'status': 'uploaded'}

def validate_password(password):
    # Check password length
    return len(password) > 3
\`\`\`

SECURITY CHECKS:
1. SQL injection vulnerabilities?
2. File upload risks?
3. Password strength validation?
4. Input validation present?
5. Authentication/authorization?

RESPOND: FAIL with critical security findings"
```

### 5. Performance Analysis

**Identify performance issues and bottlenecks:**

```bash
ollama run qwen3-coder "TASK: Identify performance issues

CODE:
\`\`\`python
def get_user_with_posts(user_id):
    # Get user
    user = db.session.query(User).filter(User.id == user_id).first()

    # Get all posts (N+1 problem)
    posts = db.session.query(Post).filter(Post.user_id == user_id).all()

    # Get comments for each post (N+1 problem)
    for post in posts:
        comments = db.session.query(Comment).filter(
            Comment.post_id == post.id
        ).all()
        post.comments = comments

    return {'user': user, 'posts': posts}

# API endpoint processes many requests
@app.route('/api/export')
def export_data():
    users = db.session.query(User).all()  # 100k records
    # Process all in memory
    for user in users:
        process_user(user)
    # Return all
    return users
\`\`\`

PERFORMANCE CHECKS:
1. N+1 query problems?
2. Memory efficiency?
3. Query optimization possible?
4. Caching opportunities?
5. Bulk operations possible?

RESPOND: ISSUES with severity and fixes"
```

### 6. Type Safety Review

**Verify TypeScript types are correct:**

```bash
ollama run qwen3-coder "TASK: Review TypeScript types

CODE:
\`\`\`typescript
interface User {
  id: number;
  name: string;
  email: string;
  age?: number;
}

function createUser(data: any): User {
  return {
    id: Math.random(),
    name: data.name,
    email: data.email
  };
}

async function fetchUser(id: number): Promise<User | null> {
  const response = await fetch(\`/api/users/\${id}\`);
  if (response.ok) {
    return response.json();
  }
  return null;
}

function updateUser(user: User, updates: object): User {
  return { ...user, ...updates };
}
\`\`\`

TYPE CHECKS:
1. Type annotations complete?
2. Any types unsafe?
3. Return types correct?
4. Type narrowing proper?
5. Null/undefined handling?

RESPOND: PASS/ISSUES with specific recommendations"
```

## Batch Verification Workflow

**Verify multiple files in a project:**

```bash
#!/bin/bash

# Find all Python files
FILES=$(find . -name "*.py" -not -path "./venv/*" -not -path "./.git/*")

# Create analysis report
echo "=== CODE VERIFICATION REPORT ===" > verification_report.txt
echo "Generated: $(date)" >> verification_report.txt
echo "" >> verification_report.txt

for FILE in $FILES; do
  echo "Verifying: $FILE"

  # Read file
  CONTENT=$(cat "$FILE")

  # Get line count to determine verification depth
  LINES=$(wc -l < "$FILE")

  if [ "$LINES" -lt 50 ]; then
    # Full verification for small files
    ollama run qwen3-coder "Verify this Python code for correctness and best practices:

\`\`\`python
$CONTENT
\`\`\`

Respond: PASS/FAIL with findings" >> verification_report.txt
  else
    # Sample verification for large files
    HEAD=$(head -30 "$FILE")
    ollama run qwen3-coder "Verify this Python code sample for critical issues:

\`\`\`python
$HEAD
\`\`\`

Respond: ISSUES or OK" >> verification_report.txt
  fi

  echo "---" >> verification_report.txt
done

echo "Report saved to verification_report.txt"
```

## Code Review Integration

**Use Ollama in code review workflow:**

```bash
#!/bin/bash
# review-with-ollama.sh

BRANCH="${1:-origin/main}"
FILES=$(git diff --name-only $BRANCH...HEAD | grep -E '\.(py|ts|js)$')

echo "=== CODE REVIEW with Ollama ==="
echo "Comparing: $BRANCH...HEAD"
echo ""

for FILE in $FILES; do
  echo "Reviewing: $FILE"

  # Get the diff
  DIFF=$(git diff $BRANCH...HEAD -- "$FILE")

  # Get current file content
  CONTENT=$(git show HEAD:$FILE)

  # Review with Ollama
  ollama run qwen3-coder "TASK: Code review of changes

CHANGED FILE: $FILE

CURRENT CONTENT:
\`\`\`
$CONTENT
\`\`\`

DIFF:
\`\`\`diff
$DIFF
\`\`\`

REVIEW CHECKLIST:
1. Any bugs or issues?
2. Does code follow patterns?
3. Are there better approaches?
4. Any security/performance concerns?
5. Tests adequate?

RESPOND: Short review with key findings"

  echo "---"
done
```

## Pattern Analysis

**Analyze patterns across codebase:**

```bash
# Find a pattern
grep -r "async def" --include="*.py" src/ | head -10 > async_examples.txt

# Analyze with Ollama
ollama run qwen3-coder "Analyze these async Python functions for consistency and best practices:

$(cat async_examples.txt)

Provide feedback on:
1. Pattern consistency
2. Error handling approach
3. Suggestions for improvement"
```

## ChromaDB Integration

**Store verification results in ChromaDB:**

```python
# After verification with Ollama, embed and store result
from chromadb import Client

client = Client()
collection = client.get_or_create_collection("code_verifications")

# Embed verification result
embedding = ollama_embed("This code verifies correctly...")

collection.add(
    ids=["verify_user_auth_001"],
    documents=["User authentication implementation verified"],
    metadatas={
        "file": "app/auth.py",
        "verification_method": "ollama:qwen3-coder",
        "status": "PASS",
        "timestamp": datetime.now().isoformat()
    },
    embeddings=[embedding]
)

# Later: search for similar verified patterns
results = collection.query(
    query_texts=["how do we verify new auth code?"],
    n_results=5
)
```

## Pre-Commit Hook Integration

**Verify code before committing:**

```bash
#!/bin/bash
# .git/hooks/pre-commit

set -euo pipefail

# Get staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(py|ts|js)$' || true)

if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

echo "Verifying code with Ollama..."

FAILED=0
for FILE in $STAGED_FILES; do
  if [ ! -f "$FILE" ]; then
    continue
  fi

  CONTENT=$(git show :$FILE)

  # Quick verification
  RESULT=$(ollama run qwen3-coder "Quick syntax check - respond only PASS or FAIL:
\`\`\`
$CONTENT
\`\`\`" 2>&1)

  if [[ ! "$RESULT" =~ "PASS" ]]; then
    echo "WARNING: Verification issues in $FILE"
    FAILED=1
  fi
done

if [ $FAILED -eq 1 ]; then
  echo "Some files have verification issues. Review before committing."
  exit 1
fi

exit 0
```

## Context Curator Enrichment

**Enhance Context Curator with verification metadata:**

```bash
# After verifying a file, update CLAUDE.local.md with results

VERIFY_RESULT=$(ollama run qwen3-coder "Analyze and summarize this code:
$(cat src/auth.py)" 2>&1)

# Add to Context Curator enrichment
cat >> .claude/CLAUDE.local.md << EOF

### Code Verification: src/auth.py
**Timestamp**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Tool**: ollama:qwen3-coder
**Status**: Verified

**Analysis**:
$VERIFY_RESULT

EOF
```

## Error Handling

**Handle Ollama unavailability gracefully:**

```bash
check_ollama() {
  if ! curl -s http://127.0.0.1:11434/api/tags > /dev/null 2>&1; then
    echo "ERROR: Ollama is not running"
    echo "Start with: ollama serve"
    return 1
  fi
  return 0
}

verify_with_fallback() {
  local CODE="$1"
  local TASK="$2"

  if check_ollama; then
    ollama run qwen3-coder "$TASK"
  else
    echo "WARNING: Ollama unavailable, skipping verification"
    return 2
  fi
}
```

## Performance Tips

- Ollama requests: 5-30s for code analysis
- Cache verification results for identical code
- Batch multiple checks in one request
- Use smaller code samples for quick checks
- Full analysis for critical code, quick checks for routine reviews

## Summary

Local-first verification with Ollama:
- No external API calls
- Fast turnaround (5-30s)
- Integrates with development workflow
- Works offline
- Cacheable and repeatable
