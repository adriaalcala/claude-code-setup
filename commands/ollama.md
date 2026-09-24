# Ollama Command

Quick-access command for local Ollama operations.

## Usage

```bash
/ollama <operation> [arguments] [options]
```

## Operations

### list
List available models.

```bash
/ollama list
```

Output:
```
Available Models (Loaded/Unloaded)
==================================

LOADED:
- qwen3-coder:latest (8.3 GB, last used 2 mins ago)
- nomic-embed-text:latest (0.3 GB, last used 15 mins ago)

AVAILABLE:
- mistral:latest
- neural-chat:latest
- llama2:latest
```

### run
Run a model with a prompt.

```bash
/ollama run qwen3-coder "What are async/await?"
```

Options:
- `--stream`: Stream output (default: true)
- `--temperature <n>`: Creativity level 0-2 (default: 0.7)
- `--top-p <n>`: Diversity parameter 0-1 (default: 0.9)
- `--timeout <s>`: Request timeout in seconds (default: 300)

### status
Check Ollama service status.

```bash
/ollama status
```

Output:
```
Ollama Status
=============

Service: RUNNING
URL: http://127.0.0.1:11434
Uptime: 24h 15m

Loaded Models:
- qwen3-coder (2.3 GB resident)
- nomic-embed-text (0.2 GB resident)

Memory Usage: 2.5 GB / 16 GB
Load Average: 0.45
```

### pull
Download/pull a model.

```bash
/ollama pull qwen3-coder
```

Options:
- `--variant <name>`: Model variant (e.g., "q4")

### verify
Verify model functionality.

```bash
/ollama verify qwen3-coder
```

Output:
```
Model Verification: qwen3-coder
===============================

Loading model... ✓
Testing inference... ✓
Checking output quality... ✓

Status: READY
Last verified: 2026-03-08T14:32:15Z
Average response time: 2.3s
```

### embed
Get embeddings for text (using nomic-embed-text).

```bash
/ollama embed "How do I use async/await?"
```

Output:
```
Embedding Vector
================

Text: "How do I use async/await?"
Model: nomic-embed-text
Dimension: 768

Vector: [0.1234, -0.5678, 0.9012, ...]
```

Options:
- `--model <name>`: Embedding model (default: nomic-embed-text)
- `--output <format>`: json or text (default: json)

### health
Detailed health check.

```bash
/ollama health
```

Output:
```
Ollama Health Check
===================

Service Health: HEALTHY
API Response: 124ms
Model Load Time: 456ms
Inference Speed: 45 tokens/sec

Resources:
- Memory: 2.5 GB / 16 GB (15%)
- GPU: Not available
- Disk: 45 GB / 500 GB (9%)

Recent Requests:
- Last 1h: 142 requests
- Avg Response: 2.3s
- Error Rate: 0.2%

Status: READY FOR USE
```

### analyze
Analyze code with qwen3-coder.

```bash
/ollama analyze src/services/user_service.py
```

Options:
- `--file <path>`: File to analyze
- `--focus <area>`: correctness, performance, security, design

Output:
```
Code Analysis: src/services/user_service.py
============================================

File Size: 245 lines
Language: Python
Complexity: Medium

ANALYSIS

Strengths:
✓ Well-structured code organization
✓ Type hints present
✓ Error handling implemented

Issues Found:
1. Line 45: Missing null check for user object
2. Line 78: N+1 query pattern detected
3. Line 123: Hardcoded configuration value

Suggestions:
- Extract validation to separate method
- Use eager loading for relationships
- Move config to environment variables

Overall: GOOD (minor improvements suggested)
```

## Examples

### Code Verification
```bash
# Verify syntax and correctness
/ollama run qwen3-coder "Verify this Python code:
\`\`\`python
async def fetch_data(url: str) -> dict:
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as resp:
            return await resp.json()
\`\`\`"
```

### Pattern Explanation
```bash
# Explain a design pattern
/ollama run qwen3-coder "Explain the Repository Pattern with Python example"
```

### Code Review
```bash
# Quick code review
/ollama run qwen3-coder "Review this REST endpoint for security issues:
POST /api/users
{
  'name': request.args['name'],
  'email': request.args['email']
}"
```

### API Design Review
```bash
# Review API design
/ollama run qwen3-coder "Is this REST API design correct?
GET /api/users/{id}/profile
Response: {user_id, email, posts: []}"
```

### Architecture Discussion
```bash
# Architecture question
/ollama run qwen3-coder "When should I use async/await in Python? Give practical examples."
```

## Integration with Other Commands

### With Code Review
```bash
# Review with Ollama verification
/review src/app.py
# Internally uses /ollama run for complex analysis
```

### With Docs Search
```bash
# Enhanced search results
/docs "async patterns" --enhanced-with-ollama
# Results include Ollama-generated summaries
```

### With Anti-Hallucination Skill
```bash
# Verification chain
User asks a claim → Skill uses /ollama verify → Falls back to WebSearch if needed
```

## Performance Tips

1. **Warm up models** - First request is slower (model loading)
   ```bash
   /ollama run qwen3-coder "test" --temperature 0.5
   ```

2. **Use appropriate temperature**
   - 0.0: Deterministic (code analysis)
   - 0.5-0.7: Balanced (default)
   - 1.0+: Creative (brainstorming)

3. **Monitor memory**
   ```bash
   /ollama status
   ```

4. **Batch requests**
   ```bash
   # Better: Analyze multiple files in one prompt
   /ollama run qwen3-coder "Analyze these files: [file1], [file2], [file3]"
   ```

## Configuration

### Ollama Service
```bash
# Start Ollama with custom settings
OLLAMA_NUM_CTX=4096 OLLAMA_NUM_THREAD=8 ollama serve
```

### Temperature Presets
```bash
# Code analysis (precise)
/ollama run qwen3-coder [...] --temperature 0.2

# General assistance (balanced)
/ollama run qwen3-coder [...] --temperature 0.7

# Creative thinking (high variability)
/ollama run qwen3-coder [...] --temperature 1.2
```

## Troubleshooting

### Ollama Not Running
```bash
# Check status
curl -s http://127.0.0.1:11434/api/tags

# Start if not running
ollama serve

# Check logs
tail -50 ~/.ollama/logs/*
```

### Models Not Loaded
```bash
# List models
ollama list

# Pull required model
ollama pull qwen3-coder

# Verify
/ollama verify qwen3-coder
```

### Slow Response
```bash
# Check resource usage
/ollama health

# Reduce context if needed
/ollama run qwen3-coder "..." --temperature 0.5

# Check available GPU
ollama list -v
```

## Common Workflows

### Code Analysis Workflow
```bash
1. /ollama analyze src/file.py --focus correctness
2. Review findings
3. /review src/file.py (for official review)
4. Make changes
5. /ollama verify src/file.py
```

### Documentation Workflow
```bash
1. /docs "topic" (search existing docs)
2. If not found: /ollama run qwen3-coder "Explain topic"
3. Write up findings
4. Add to docs/
5. Update Context Curator index
```

### Code Review Workflow
```bash
1. /ollama analyze file.py (quick check)
2. /review file.py (full review)
3. Make fixes
4. /ollama verify file.py (confirmation)
5. Commit and push
```

## API Integration

For programmatic access:

```bash
# Get embeddings (for semantic search)
curl -X POST http://127.0.0.1:11434/api/embed \
  -d '{"model": "nomic-embed-text", "input": "text here"}'

# Run model
curl -X POST http://127.0.0.1:11434/api/generate \
  -d '{
    "model": "qwen3-coder",
    "prompt": "Your prompt here",
    "stream": false
  }'
```

## Related Commands

- `/review` - Code review (uses Ollama for complex analysis)
- `/docs` - Documentation search (can use Ollama for summaries)
- `/brainstorm` - Brainstorming (uses Ollama for idea generation)

## Limitations

- Response time: 5-30 seconds depending on prompt complexity
- Context window: Limited to model's max tokens
- No internet access (local only)
- GPU not available (CPU inference only)

## Future Enhancements

- [ ] Batch processing for multiple files
- [ ] Custom model fine-tuning
- [ ] Streaming output improvements
- [ ] Performance profiling integration
- [ ] Automated suggestion integration
