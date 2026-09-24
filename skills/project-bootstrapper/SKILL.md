---
name: project-bootstrapper
description: "Create complete project scaffolds with .claude/ config, CI/CD, tests, docs. Supports Python (uv/ruff/pytest), TypeScript (pnpm/prettier/vitest), FastAPI, React, CLI tools. Trigger on 'new project', 'scaffold', 'bootstrap', 'create project', 'init project', 'start a new'."
---

# Project Bootstrapper Skill

## Overview
Generate complete, production-ready project scaffolds with testing, CI/CD, linting, formatting, and Claude agent configuration.

## Phase 1: INTERVIEW
Gather project requirements:

### Project Type
- Web API (FastAPI, Express, Spring)
- Web Frontend (React, Vue, Svelte)
- CLI Tool (Python Click, Node Commander, Rust)
- Library (Python package, TypeScript/npm)
- Full-stack (React + FastAPI)
- Data pipeline (Python scripts, Jupyter)
- Agent/bot (LLM tooling, Discord bot)

### Language & Runtime
- Python (3.10+) with uv/pip
- TypeScript/Node.js with pnpm/npm
- Rust with cargo
- Other?

### Framework (if applicable)
- FastAPI (async Python REST)
- Express (Node.js)
- Spring Boot (Java)
- React (frontend)
- Vue (frontend)
- Svelte (frontend)

### Key Features
- Database (PostgreSQL, SQLite, MongoDB)?
- Authentication (JWT, OAuth2, session)?
- Testing? (pytest, vitest)
- Docker support?
- Monitoring/logging?
- Documentation (Sphinx, MkDocs)?
- Code quality tools? (ruff, eslint, prettier)

### Project Metadata
- Project name (snake_case for Python, kebab-case for npm)
- Description (1-2 sentences)
- Author/owner
- License (MIT, Apache-2.0, etc.)

## Phase 2: SCAFFOLD
Create complete directory structure:

### Python Project (uv + pytest + ruff)
```
myproject/
  .git/
  .gitignore
  .github/
    workflows/
      ci.yml
  pyproject.toml
  uv.lock
  README.md
  CLAUDE.md
  .claude/
    settings.json
    hooks/
    rules/
  src/
    myproject/
      __init__.py
      main.py
      utils.py
      config.py
  tests/
    __init__.py
    test_main.py
    conftest.py
  docs/
    index.md
    api.md
  .env.example
  Dockerfile
```

### TypeScript Project (pnpm + vitest + prettier)
```
myproject/
  .git/
  .gitignore
  .github/
    workflows/
      ci.yml
  package.json
  pnpm-lock.yaml
  tsconfig.json
  vite.config.ts
  vitest.config.ts
  README.md
  CLAUDE.md
  .claude/
    settings.json
    hooks/
    rules/
  src/
    index.ts
    utils.ts
    types.ts
  tests/
    unit/
      index.test.ts
    integration/
  docs/
    index.md
  .env.example
  Dockerfile
```

### FastAPI Project (includes web server)
```
myproject/
  .git/
  .gitignore
  .github/workflows/ci.yml
  pyproject.toml
  uv.lock
  README.md
  CLAUDE.md
  .claude/
    settings.json
  app/
    __init__.py
    main.py
    config.py
    models/
      __init__.py
      user.py
      item.py
    routes/
      __init__.py
      users.py
      items.py
    database.py
    dependencies.py
  tests/
    conftest.py
    test_main.py
    test_api.py
  alembic/
    env.py
    script.py.mako
    versions/
  docs/
    index.md
    api.md
  .env.example
  Dockerfile
  docker-compose.yml
```

### React Project (includes frontend)
```
myproject/
  .git/
  .gitignore
  .github/workflows/ci.yml
  package.json
  pnpm-lock.yaml
  tsconfig.json
  vite.config.ts
  vitest.config.ts
  README.md
  CLAUDE.md
  .claude/
    settings.json
  src/
    components/
      App.tsx
      Button.tsx
      Card.tsx
    pages/
      Home.tsx
      About.tsx
    hooks/
      useAuth.ts
    services/
      api.ts
      auth.ts
    store/
      index.ts
    App.tsx
    main.tsx
  public/
    index.html
    favicon.svg
  tests/
    unit/
      App.test.tsx
    integration/
  docs/
    architecture.md
  .env.example
  Dockerfile
```

## Phase 3: CONFIGURE
Generate configuration files:

### pyproject.toml (Python)
```toml
[project]
name = "myproject"
version = "0.1.0"
description = "Project description"
authors = [{name = "Your Name", email = "you@example.com"}]
license = {text = "MIT"}
requires-python = ">=3.10"
dependencies = [
  "fastapi>=0.100.0",
  "pydantic>=2.0.0",
  "uvicorn>=0.23.0",
]

[project.optional-dependencies]
dev = [
  "pytest>=7.4.0",
  "pytest-cov>=4.1.0",
  "pytest-asyncio>=0.21.0",
  "ruff>=0.1.0",
  "black>=23.0.0",
  "mypy>=1.5.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.ruff]
line-length = 100
target-version = "py310"

[tool.ruff.lint]
extend-select = ["I", "E", "W", "F", "UP"]

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
addopts = "--cov=src --cov-report=term-missing"

[tool.mypy]
python_version = "3.10"
strict = true
```

### package.json (TypeScript/Node)
```json
{
  "name": "myproject",
  "version": "0.1.0",
  "description": "Project description",
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "lint": "eslint . --ext .ts,.tsx",
    "format": "prettier --write .",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "axios": "^1.6.0"
  },
  "devDependencies": {
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.0.0",
    "prettier": "^3.0.0",
    "typescript": "^5.0.0",
    "vite": "^5.0.0",
    "vitest": "^0.34.0"
  }
}
```

### .github/workflows/ci.yml
Python example:
```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v2
      - run: uv sync --all-extras
      - run: uv run pytest --cov
      - run: uv run ruff check .
      - run: uv run mypy src/
  
  build:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/build-push-action@v5
        with:
          context: .
          push: false
```

TypeScript example:
```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
        with:
          version: 8
      - uses: actions/setup-node@v4
        with:
          node-version: 18
          cache: pnpm
      - run: pnpm install
      - run: pnpm test
      - run: pnpm lint
      - run: pnpm type-check
```

### .claude/settings.json
```json
{
  "project_name": "myproject",
  "project_type": "web-api",
  "language": "python",
  "framework": "fastapi",
  "testing_framework": "pytest",
  "code_quality": {
    "linter": "ruff",
    "formatter": "black",
    "type_checker": "mypy"
  },
  "ci_cd": "github-actions",
  "docker": true,
  "database": "postgresql",
  "local_first": {
    "enabled": true,
    "ollama_host": "http://localhost:11434",
    "preferred_models": [
      "qwen3-coder",
      "nomic-embed-text"
    ]
  }
}
```

### .claude/CLAUDE.md (Project-specific Claude instructions)
Auto-generated based on project type:

**Python/FastAPI example:**
```markdown
# Claude Project Guide for myproject

## Project Overview
- **Type**: Web API (FastAPI)
- **Language**: Python 3.10+
- **Package Manager**: uv
- **Testing**: pytest with asyncio support
- **Linting**: ruff, mypy
- **Database**: PostgreSQL with Alembic migrations

## Local-First Development
This project uses Ollama (qwen3-coder) for:
- Code review and refactoring suggestions
- Architecture analysis before major changes
- Commit message generation
- Documentation drafting

Never send code to cloud APIs without explicit approval.

## Setup
```bash
uv sync --all-extras
uv run pytest
```

## Code Standards
- Use type hints (mypy strict mode)
- Async/await for I/O operations
- Pydantic models for validation
- Comprehensive docstrings

## Adding Dependencies
```bash
uv add packagename
uv add --group dev devtoolname
```

## Testing
```bash
uv run pytest --cov=src
uv run pytest -k test_name -v
```

## Running
```bash
uv run uvicorn app.main:app --reload
```
```

### .gitignore
```
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST
.pytest_cache/
.coverage
htmlcov/

# TypeScript/Node
node_modules/
dist/
build/
*.tsbuildinfo
.next/

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Environment
.env
.env.local
.env.*.local

# Misc
.git/
```

### README.md (template)
```markdown
# MyProject

Brief description of what your project does.

## Features
- Feature 1
- Feature 2
- Feature 3

## Quick Start

### Prerequisites
- Python 3.10+ OR Node.js 18+

### Installation
```bash
# Python
uv sync

# TypeScript
pnpm install
```

### Running
```bash
# Python
uv run python -m myproject

# TypeScript
npm run dev
```

### Testing
```bash
# Python
uv run pytest

# TypeScript
pnpm test
```

## Architecture
[Describe key components and design]

## API Documentation
[Link to OpenAPI docs or provide overview]

## Contributing
[Contribution guidelines]

## License
MIT
```

### .env.example
```
# Database
DATABASE_URL=postgresql://user:pass@localhost/mydb

# API Keys
API_KEY=your-api-key-here

# Environment
DEBUG=false
LOG_LEVEL=INFO
```

## Phase 4: VERIFY
Ensure setup is complete:

### Install Dependencies
```bash
# Python
uv sync --all-extras

# TypeScript
pnpm install
```

### Run Tests
```bash
# Python
uv run pytest

# TypeScript
pnpm test
```

### Lint & Format
```bash
# Python
uv run ruff check .
uv run mypy src/

# TypeScript
pnpm lint
pnpm format
```

### Verify Structure
- All required directories exist
- All config files present
- CI/CD workflow valid
- README complete
- .claude/ configuration matches project

If any checks fail, fix and re-test.

## Local-First: Ollama Integration
Generate initial CLAUDE.md based on project type using Ollama:

```bash
ollama run qwen3-coder << 'EOF'
Generate a Claude project guide for a [PROJECT_TYPE] project in [LANGUAGE].
Include: setup steps, code standards, testing approach, local-first development notes.
Format as markdown suitable for .claude/CLAUDE.md.
EOF
```

This creates personalized guidance without cloud API calls, keeping project decisions local.

