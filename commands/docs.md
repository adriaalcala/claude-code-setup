# Docs Search Command

Quick-access command for searching project documentation.

## Usage

```bash
/docs [query] [options]
```

## Options

- `--query <text>`: Search query (required if not specified as argument)
- `--scope <scope>`: Search scope: all, code, guides, api, architecture (default: all)
- `--format <format>`: Output format: text, markdown, json (default: markdown)
- `--max-results <n>`: Maximum results to return (default: 10)
- `--include-external`: Include external documentation links
- `--offline`: Use offline documentation only

## Examples

### Search Documentation
```bash
/docs "async/await patterns"
```

### API Documentation
```bash
/docs "user endpoint" --scope api
```

### Architecture Guides
```bash
/docs "database schema" --scope guides
```

### Search with JSON Output
```bash
/docs "authentication" --format json --max-results 5
```

### Offline-Only Search
```bash
/docs "REST API" --offline
```

## Search Scopes

### all (default)
Searches entire documentation:
- Code comments
- Docstrings
- README
- Architecture guides
- API documentation
- External resources

### code
Searches code-related documentation:
- Docstrings
- Code comments
- Inline examples
- Design patterns
- Code snippets

### guides
Searches guides and tutorials:
- README
- Getting Started
- Architecture guides
- Design decisions
- Best practices

### api
Searches API documentation:
- API endpoints
- Request/response schemas
- Error codes
- Examples
- Authentication

### architecture
Searches architecture documentation:
- System design
- Component relationships
- Data flow
- Technology decisions
- Infrastructure

## Output

### Markdown Output (default)
```
Docs Search Results: "async/await patterns"
==============================================

Found 3 results

## Result 1: Python Async/Await Guide
**Type:** Guide | **Location:** docs/ASYNC.md
**Relevance:** 95%

Introduction to async/await in Python, covering coroutines,
event loops, and common patterns...

[View Full Doc](docs/ASYNC.md)

---

## Result 2: Async Service Implementation
**Type:** Code | **Location:** src/services/README.md
**Relevance:** 87%

Best practices for implementing async services using FastAPI
and asyncio...

[View Full Doc](src/services/README.md)

---

## Result 3: Testing Async Code
**Type:** Guide | **Location:** docs/TESTING.md
**Relevance:** 72%

Guide to testing asynchronous code with pytest-asyncio...

[View Full Doc](docs/TESTING.md)
```

### JSON Output
```json
{
  "query": "async/await patterns",
  "timestamp": "2026-03-08T14:32:15Z",
  "results_count": 3,
  "results": [
    {
      "title": "Python Async/Await Guide",
      "type": "guide",
      "location": "docs/ASYNC.md",
      "relevance": 0.95,
      "excerpt": "Introduction to async/await in Python...",
      "url": "file:///path/to/docs/ASYNC.md"
    }
  ]
}
```

## Integration with Context Curator

The `/docs` command integrates with Context Curator for:
- Semantic search using embeddings
- Cross-project documentation linking
- Smart relevance ranking
- Automatic index updates

## Documentation Priority

1. **Local documentation** (in repository)
   - Code comments
   - Docstrings
   - docs/ directory
   - README files

2. **Project guides** (Context Curator indexed)
   - Architecture decisions
   - Design patterns
   - Best practices

3. **External resources** (when --include-external)
   - Official docs (Python, FastAPI, etc.)
   - Standard references
   - Framework documentation

## Tips

1. **Use specific queries** - "user authentication flow" better than "authentication"
2. **Combine scopes** - Search API docs first, then guides for context
3. **Check code examples** - Often in docstrings or docs/examples/
4. **Related docs** - Each result shows related topics
5. **JSON format** - Better for programmatic processing

## Common Searches

```bash
# API endpoints
/docs "POST /api/users" --scope api

# Database schema
/docs "user table schema" --scope guides

# Error handling
/docs "error handling" --scope code

# Configuration
/docs "environment variables" --scope guides

# Testing
/docs "how to test this component" --scope guides
```

## Limitations

- Offline mode limited to indexed documentation
- External docs require network access
- Large result sets may take longer
- Some internal docs may not be indexed

## Related Commands

- `/review` - Code review
- `/commit` - Conventional commits
- `/brainstorm` - Brainstorming session

## Performance

- **Quick search:** <1 second
- **Semantic search:** 1-3 seconds
- **Cross-project search:** 2-5 seconds

Results are cached for 1 hour to improve performance.
