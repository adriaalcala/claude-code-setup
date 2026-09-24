---
name: ci-cd-builder
description: "Generate CI/CD pipelines (GitHub Actions, GitLab CI). Detects language, testing framework, linters, formatters. Handles matrix builds, caching, secrets management. Trigger on 'ci/cd', 'setup ci', 'github actions', 'pipeline', 'automate tests'."
---

# CI/CD Builder Skill

## Overview
Generate production-ready CI/CD pipelines that automate testing, linting, building, and deployment across multiple languages and platforms.

## Phase 1: DETECT

### Detect Project Language
Check for language indicators:
- Python: `pyproject.toml`, `setup.py`, `requirements.txt`, `Pipfile`, `*.py` files
- Node.js: `package.json`, `yarn.lock`, `pnpm-lock.yaml`, `*.js`, `*.ts` files
- Go: `go.mod`, `go.sum`, `*.go` files
- Rust: `Cargo.toml`, `Cargo.lock`, `*.rs` files
- Java: `pom.xml`, `build.gradle`, `*.java` files
- Other: infer from file extensions

### Detect Testing Framework
- Python: `pytest`, `unittest`, `nose`, `tox`
- Node.js: `jest`, `vitest`, `mocha`, `tap`
- Go: `testing` (built-in)
- Rust: `cargo test` (built-in)
- Java: `junit`, `testng`

### Detect Linters & Formatters
- Python: `ruff`, `flake8`, `pylint`, `black`, `isort`, `mypy`
- Node.js: `eslint`, `prettier`, `typescript`
- Go: `golangci-lint`, `gofmt`
- Rust: `clippy`, `rustfmt`
- Java: `checkstyle`, `spotbugs`

### Detect Build System
- Python: `setuptools`, `uv`, `pip`, `poetry`
- Node.js: `npm`, `pnpm`, `yarn`
- Go: `go build`
- Rust: `cargo build`
- Java: `maven`, `gradle`

### Detect Docker
- `Dockerfile` present?
- `docker-compose.yml` present?
- Multi-stage build needed?

## Phase 2: DESIGN

### Define Pipeline Stages
1. **Checkout** — clone repo
2. **Setup** — install dependencies, cache if applicable
3. **Lint** — run code quality tools (ruff, eslint, etc.)
4. **Type Check** — mypy, tsc
5. **Format Check** — prettier, black (in check mode)
6. **Test** — run test suite with coverage
7. **Build** — compile/bundle if needed
8. **Security** — optional (SAST, dependency checks)
9. **Deploy** — optional (upload artifacts, push Docker image)

### Matrix Strategy
Define matrix for:
- **OS**: ubuntu-latest, macos-latest, windows-latest (if needed)
- **Python version**: 3.10, 3.11, 3.12 (Python projects)
- **Node version**: 16, 18, 20 (Node projects)
- **Architecture**: x86_64, arm64 (if supporting both)

Parallel execution saves time.

### Caching Strategy
- **Dependencies**: Cache pip/npm packages
  - Python: `~/.cache/pip`, `~/.cache/uv`
  - Node: `node_modules/`, `.pnpm-store/`
- **Build artifacts**: Cache compiled outputs (if applicable)
- **Linter caches**: Some tools cache results

### Secrets Management
- Use GitHub Secrets for sensitive data (API keys, tokens, credentials)
- Reference as `${{ secrets.SECRET_NAME }}`
- Never log secrets
- Use environment variables for non-sensitive config

## Phase 3: GENERATE

### GitHub Actions Workflow (YAML)

**Python Project (uv + pytest + ruff)**

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
    strategy:
      matrix:
        python-version: ['3.10', '3.11', '3.12']
    steps:
      - uses: actions/checkout@v4

      - uses: astral-sh/setup-uv@v2
        with:
          python-version: ${{ matrix.python-version }}

      - name: Install dependencies
        run: uv sync --all-extras

      - name: Lint with ruff
        run: uv run ruff check .

      - name: Type check with mypy
        run: uv run mypy src/

      - name: Format check with black
        run: uv run black --check .

      - name: Test with pytest
        run: uv run pytest --cov=src --cov-report=xml

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.xml
          flags: unittests
          name: codecov-umbrella

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: astral-sh/setup-uv@v2

      - name: Build package
        run: uv build

      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: dist
          path: dist/
```

**TypeScript/Node Project (pnpm + vitest + eslint)**

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
    strategy:
      matrix:
        node-version: [16.x, 18.x, 20.x]
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v2
        with:
          version: 8

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: pnpm

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Lint with eslint
        run: pnpm lint

      - name: Format check with prettier
        run: pnpm format:check

      - name: Type check with tsc
        run: pnpm type-check

      - name: Test with vitest
        run: pnpm test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage-final.json
          flags: unittests

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v2
        with:
          version: 8

      - uses: actions/setup-node@v4
        with:
          node-version: '20.x'
          cache: pnpm

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Build
        run: pnpm build

      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: dist
          path: dist/
```

**FastAPI + Docker**

```yaml
name: CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
    steps:
      - uses: actions/checkout@v4

      - uses: astral-sh/setup-uv@v2
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: uv sync --all-extras

      - name: Run tests
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
        run: uv run pytest --cov=app

      - name: Upload coverage
        uses: codecov/codecov-action@v3

  build-image:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: docker/setup-buildx-action@v3

      - uses: docker/build-push-action@v5
        with:
          context: .
          push: false
          cache-from: type=gha
          cache-to: type=gha,mode=max
          tags: myapp:latest

  deploy:
    needs: build-image
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ secrets.DOCKER_REGISTRY }}/myapp:latest
```

### GitLab CI (Python example)

```yaml
stages:
  - lint
  - test
  - build
  - deploy

variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"

cache:
  paths:
    - .cache/pip

lint:
  stage: lint
  image: python:3.11
  script:
    - pip install ruff black mypy
    - ruff check .
    - black --check .
    - mypy src/

test:
  stage: test
  image: python:3.11
  script:
    - pip install -e ".[dev]"
    - pytest --cov=src
  coverage: '/TOTAL.*\s+(\d+%)$/'

build:
  stage: build
  image: python:3.11
  script:
    - pip install build
    - python -m build
  artifacts:
    paths:
      - dist/
    expire_in: 1 day

deploy:
  stage: deploy
  script:
    - pip install twine
    - twine upload dist/*
  only:
    - tags
```

## Phase 4: VALIDATE

### YAML Syntax Check
```bash
# GitHub Actions
# Use: https://github.com/rhysd/actionlint
actionlint .github/workflows/*.yml

# or
yamllint .github/workflows/
```

### Verify Action Existence
- Check actions are real: `github.com/actions/checkout@v4`
- Verify version tags exist
- Check marketplace for third-party actions

### Verify Secrets
- All `${{ secrets.X }}` must exist in GitHub/GitLab settings
- Never hardcode credentials

### Test Matrix
- Verify matrix values are valid (e.g., Python versions available)
- Check os values: ubuntu-latest, macos-latest, windows-latest

### Dry Run (Local Testing)
Use `act` (local GitHub Actions runner):
```bash
# Install: https://github.com/nektos/act
act push -j test
# Runs workflow locally to verify before pushing
```

## Local-First: Ollama Optimization
Use Ollama for YAML optimization and suggestions:

```bash
ollama run qwen3-coder << 'EOF'
Review this GitHub Actions workflow for:
1. Redundant steps
2. Caching opportunities
3. Security issues
4. Performance improvements

Suggest optimizations.

[PASTE WORKFLOW YAML]
EOF
```

Benefits:
- Fast local syntax validation
- No cloud API calls
- Iterative refinement before commit

## Common Patterns

### Conditional Execution
```yaml
- name: Deploy
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  run: ./deploy.sh
```

### Skip CI on Commit
```
git commit -m "docs: update readme [skip ci]"
```

### Set Output Variables
```yaml
- name: Set version
  id: version
  run: echo "VERSION=$(cat VERSION)" >> $GITHUB_OUTPUT

- name: Use version
  run: echo ${{ steps.version.outputs.VERSION }}
```

### Reusable Workflows
Create `.github/workflows/test.yml` as reusable:
```yaml
# In main workflow:
jobs:
  test:
    uses: ./.github/workflows/test.yml
```

## Troubleshooting

### Workflow not triggering
- Check branch filter in `on:` section
- Verify filter path if using paths filter
- Check permissions in GitHub

### Tests pass locally, fail in CI
- Different OS or environment
- Missing dependencies in cache
- Environment variables not set in CI
- Directory case sensitivity (macOS vs Linux)

### Timeout issues
- Increase timeout (default 360 min)
- Cache dependencies to speed up
- Run tests in parallel

### Secret not available
- Secret name must match exactly (case-sensitive)
- Must be defined in GitHub settings
- PR from fork cannot access secrets (security feature)

