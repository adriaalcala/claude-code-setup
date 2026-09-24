---
name: "Anti-Hallucination Verification"
description: "Verify code and claims locally with Ollama before external tools"
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - WebSearch
  - WebFetch
preferred-model: "opus"
---

# Anti-Hallucination Verification

Verify technical claims, code correctness, and implementation details using LOCAL-FIRST strategy with Ollama before falling back to external tools.

## Decision Tree

```
Is this a verification task?
  ├─ YES: Can Ollama verify this locally?
  │   ├─ YES (code patterns, syntax, logic, APIs)
  │   │   └─ Use: ollama run qwen3-coder "<analysis prompt>"
  │   │       ├─ Extract key findings
  │   │       ├─ Log verification result
  │   │       └─ Return with confidence: LOCAL_VERIFIED
  │   │
  │   └─ NO (needs current info, external APIs, real-time data)
  │       ├─ Use: WebSearch or WebFetch
  │       ├─ Extract facts from authoritative sources
  │       ├─ Return with confidence: EXTERNAL_VERIFIED
  │       └─ Cache result for future queries
  │
  └─ NO: Continue normal task execution
```

## Verification Scope

### Local Verification (Ollama) - Use First
- Code syntax correctness
- Python/TypeScript/JavaScript conventions
- REST API design patterns
- Docker best practices
- Git workflow correctness
- Library API compatibility (cached knowledge)
- Regex pattern validation
- SQL query structure
- Algorithm correctness
- Design pattern application
- Security patterns (standard practices)

**Command:**
```bash
ollama run qwen3-coder "Verify this code pattern: [code]. Check for: syntax errors, best practices, performance issues. Return: PASS/FAIL with specific findings."
```

### External Verification (WebSearch/WebFetch) - Fall Back
- Current API documentation (versions released in last 6 months)
- Real-time CVE data
- Current pricing/features of services
- Breaking changes in recent releases
- Live service status
- Recent framework versions
- Current best practices (if framework is < 1 year old)

## Workflow

### 1. Identify Claim
Parse user request or code review task:
- Is this a claim about code/syntax?
- Is this about implementation patterns?
- Is this about external information?

### 2. Choose Verification Path

```bash
# Pattern 1: Syntax/Logic Verification
ollama run qwen3-coder "TASK: Verify Python code correctness
CODE:
\`\`\`python
async def fetch_data(url: str) -> dict:
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as resp:
            return await resp.json()
\`\`\`

CHECKS:
1. Is syntax correct?
2. Are there potential bugs?
3. Does it follow async/await patterns?
4. Type hints valid?

RESPOND: PASS/FAIL with specific findings."
```

```bash
# Pattern 2: Architecture Review
ollama run qwen3-coder "TASK: Review REST API design

ENDPOINT: POST /api/users/{id}/settings
REQUEST: {\"theme\": \"dark\", \"notifications\": true}
RESPONSE: {\"status\": \"success\", \"user_id\": 123}

CHECKS:
1. HTTP method appropriate?
2. Status codes correct?
3. Request/response structure follow REST?
4. Any security concerns?

RESPOND: PASS/FAIL with findings."
```

### 3. Verify Results
- Check Ollama output for clear PASS/FAIL
- Extract specific findings
- Note any uncertainties (Ollama will indicate)
- Log verification decision

### 4. Return Result
```json
{
  "claim": "The async function is correct",
  "verification_method": "LOCAL_VERIFIED",
  "tool": "ollama:qwen3-coder",
  "confidence": "HIGH",
  "findings": [
    "Syntax is correct",
    "Async/await pattern is proper",
    "Type hints are valid"
  ],
  "decision": "PASS"
}
```

## Integration with Tools

### When to Use Grep + Ollama
```bash
# Find similar code patterns in codebase
grep -r "async def" . --include="*.py" | head -5

# Verify pattern with Ollama
ollama run qwen3-coder "Review these async patterns and suggest improvements: [patterns]"
```

### When to Use Read + Ollama
```bash
# Read implementation
grep -l "def verify" src/**/*.py | xargs -I {} sh -c 'echo "=== {} ===" && head -20 {}'

# Verify with Ollama
ollama run qwen3-coder "Review this verification implementation: [code]"
```

### When to Use WebSearch (Fallback)
```bash
# Only if Ollama cannot verify
# Usually for: breaking changes, deprecated features, very new releases
```

## Anti-Hallucination Rules

1. **Trust Ollama for logical verification** - It has strong code understanding
2. **Use WebSearch for factual/temporal claims** - APIs change, versions matter
3. **Never assume Ollama knows current API versions** - Always verify with WebSearch if version-specific
4. **Combine tools strategically**:
   - Ollama: "Is this pattern correct?"
   - WebSearch: "Is this API still available?"
5. **Document uncertainty**:
   - If Ollama says "I'm not sure", escalate to human review
   - If WebSearch returns conflicting info, note both sources

## Example Task

**User:** "Does this Docker compose config handle container networking correctly?"

```bash
# Step 1: Read the file
read_file docker-compose.yml

# Step 2: Verify with Ollama
ollama run qwen3-coder "TASK: Review Docker compose file for networking

FILE:
services:
  api:
    image: myapp:latest
    ports:
      - \"3000:3000\"
    networks:
      - app-net

  db:
    image: postgres:15
    networks:
      - app-net

networks:
  app-net:
    driver: bridge

CHECKS:
1. Network definition correct?
2. Service connectivity valid?
3. Port mapping correct?
4. Any security issues?

RESPOND: PASS/FAIL with findings."

# Step 3: Return verification
echo 'Verification: LOCAL_VERIFIED via ollama:qwen3-coder
Findings:
- Network definition correct
- Services can communicate via app-net
- Port mapping allows external access
- No security issues found
Decision: PASS'
```

## Performance Tuning

- Ollama requests: 5-30s for code analysis
- Cache repeated verifications (same code = same result)
- Batch multiple checks in one request when possible
- Use context from previous verifications

## Error Handling

If Ollama is down:
```bash
if ! curl -s http://127.0.0.1:11434/api/tags > /dev/null 2>&1; then
  echo "Ollama unavailable, falling back to WebSearch for verification"
  # Use WebSearch instead
fi
```

## Summary

**Local-First Strategy:**
1. Try Ollama for logical/pattern verification (fast, local)
2. Fall back to WebSearch for factual/temporal verification (authoritative)
3. Combine results with confidence levels
4. Never trust either tool alone for critical decisions
