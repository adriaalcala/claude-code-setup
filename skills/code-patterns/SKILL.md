---
name: "Code Patterns Reference"
description: "Quick reference for REST APIs, pytest, Docker, GitHub Actions, Python async, TypeScript"
allowed-tools:
  - Read
  - Grep
  - Glob
preferred-model: "opus"
---

# Code Patterns Reference

Quick reference guide for common design patterns, architectural decisions, and best practices.

## REST API Patterns

### Standard Endpoint Structure
```python
# endpoints/users.py
from fastapi import APIRouter, HTTPException, status
from typing import Optional
from pydantic import BaseModel

router = APIRouter(prefix="/api/users", tags=["users"])

class UserCreate(BaseModel):
    email: str
    name: str
    age: Optional[int] = None

class UserResponse(BaseModel):
    id: int
    email: str
    name: str
    created_at: str

@router.get("/", response_model=list[UserResponse])
async def list_users(skip: int = 0, limit: int = 10):
    """List all users with pagination."""
    # Implementation
    pass

@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(user: UserCreate):
    """Create a new user."""
    # Implementation
    pass

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: int):
    """Get a specific user by ID."""
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.put("/{user_id}", response_model=UserResponse)
async def update_user(user_id: int, user: UserCreate):
    """Update a user."""
    pass

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(user_id: int):
    """Delete a user."""
    pass
```

### Error Response Pattern
```python
# errors.py
from fastapi import HTTPException
from enum import Enum

class ErrorCode(str, Enum):
    VALIDATION_ERROR = "VALIDATION_ERROR"
    NOT_FOUND = "NOT_FOUND"
    UNAUTHORIZED = "UNAUTHORIZED"
    CONFLICT = "CONFLICT"

class APIError(HTTPException):
    def __init__(self, code: ErrorCode, message: str, status_code: int = 400):
        super().__init__(
            status_code=status_code,
            detail={
                "code": code.value,
                "message": message
            }
        )

# Usage
raise APIError(ErrorCode.NOT_FOUND, "User not found", 404)
```

## pytest Patterns

### Test Structure
```python
# tests/test_users.py
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.fixture
async def client():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.mark.asyncio
async def test_list_users(client):
    """Test listing users returns 200."""
    response = await client.get("/api/users")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

@pytest.mark.asyncio
async def test_create_user_success(client):
    """Test creating user with valid data."""
    payload = {
        "email": "test@example.com",
        "name": "Test User",
        "age": 30
    }
    response = await client.post("/api/users", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == payload["email"]
    assert "id" in data

@pytest.mark.asyncio
async def test_create_user_validation_error(client):
    """Test creating user with invalid data."""
    payload = {"email": "invalid"}  # Missing required 'name'
    response = await client.post("/api/users", json=payload)
    assert response.status_code == 422

@pytest.mark.asyncio
async def test_get_user_not_found(client):
    """Test getting non-existent user."""
    response = await client.get("/api/users/99999")
    assert response.status_code == 404

class TestUserUpdate:
    """Group related tests in a class."""

    @pytest.mark.asyncio
    async def test_update_user_success(self, client):
        pass

    @pytest.mark.asyncio
    async def test_update_user_not_found(self, client):
        pass
```

### Fixture Pattern
```python
# tests/conftest.py
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

@pytest.fixture
def db_engine():
    """Create test database."""
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    yield engine
    Base.metadata.drop_all(engine)

@pytest.fixture
def db_session(db_engine):
    """Provide database session for tests."""
    SessionLocal = sessionmaker(bind=db_engine)
    session = SessionLocal()
    yield session
    session.close()

@pytest.fixture
def mock_config(monkeypatch):
    """Override configuration."""
    monkeypatch.setenv("ENV", "test")
    monkeypatch.setenv("DB_URL", "sqlite:///:memory:")
```

## Docker Patterns

### Production Dockerfile
```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app/ ./app/
COPY main.py .

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')" || exit 1

# Non-root user
RUN useradd -m appuser
USER appuser

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Docker Compose
```yaml
# docker-compose.yml
version: "3.9"

services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:password@db:5432/mydb
      - ENV=production
    depends_on:
      db:
        condition: service_healthy
    networks:
      - app-network
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mydb
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - app-network
    restart: unless-stopped

volumes:
  db_data:

networks:
  app-network:
    driver: bridge
```

## GitHub Actions Patterns

### CI/CD Workflow
```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.9", "3.10", "3.11"]

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python-version }}
          cache: pip

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Lint
        run: |
          ruff check .
          mypy app/

      - name: Run tests
        run: pytest --cov=app --cov-report=xml

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.xml

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Bandit
        run: |
          pip install bandit
          bandit -r app/ -f json -o bandit-report.json || true

      - name: Check dependencies
        run: |
          pip install safety
          safety check --json || true
```

## Python Async Patterns

### Async Function Definition
```python
# app/services.py
import asyncio
from typing import Coroutine

async def fetch_user(user_id: int) -> dict:
    """Fetch user data asynchronously."""
    await asyncio.sleep(0.1)  # Simulated I/O
    return {"id": user_id, "name": "User"}

async def fetch_multiple_users(user_ids: list[int]) -> list[dict]:
    """Fetch multiple users concurrently."""
    tasks = [fetch_user(uid) for uid in user_ids]
    return await asyncio.gather(*tasks)

async def process_with_timeout(coroutine: Coroutine, timeout: int = 5):
    """Execute coroutine with timeout."""
    try:
        return await asyncio.wait_for(coroutine, timeout=timeout)
    except asyncio.TimeoutError:
        raise Exception("Operation timed out")

async def retry_on_failure(coro: Coroutine, max_retries: int = 3, delay: int = 1):
    """Retry coroutine with exponential backoff."""
    for attempt in range(max_retries):
        try:
            return await coro
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            await asyncio.sleep(delay * (2 ** attempt))
```

### Async Context Manager
```python
# app/db.py
from contextlib import asynccontextmanager
import asyncpg

class AsyncDatabase:
    def __init__(self, url: str):
        self.url = url
        self.pool = None

    @asynccontextmanager
    async def get_connection(self):
        """Get database connection."""
        async with self.pool.acquire() as conn:
            yield conn

    async def connect(self):
        """Initialize connection pool."""
        self.pool = await asyncpg.create_pool(self.url)

    async def disconnect(self):
        """Close connection pool."""
        if self.pool:
            await self.pool.close()

# Usage
db = AsyncDatabase("postgresql://user:password@localhost/mydb")

async def get_user(user_id: int):
    async with db.get_connection() as conn:
        return await conn.fetchrow("SELECT * FROM users WHERE id = $1", user_id)
```

## TypeScript Patterns

### Type Definitions
```typescript
// types/user.ts
export interface UserCreate {
  email: string;
  name: string;
  age?: number;
}

export interface User extends UserCreate {
  id: number;
  createdAt: string;
  updatedAt: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
}

export type ApiResponse<T> =
  | { success: true; data: T }
  | { success: false; error: string; code: string };
```

### API Client Pattern
```typescript
// lib/api.ts
import axios, { AxiosInstance } from "axios";
import { User, UserCreate, PaginatedResponse, ApiResponse } from "@/types/user";

class UserService {
  private client: AxiosInstance;

  constructor(baseURL: string = process.env.REACT_APP_API_URL) {
    this.client = axios.create({
      baseURL,
      timeout: 10000,
      headers: {
        "Content-Type": "application/json"
      }
    });
  }

  async listUsers(page: number = 1, pageSize: number = 10): Promise<PaginatedResponse<User>> {
    const response = await this.client.get<PaginatedResponse<User>>("/users", {
      params: { page, pageSize }
    });
    return response.data;
  }

  async getUser(id: number): Promise<ApiResponse<User>> {
    try {
      const response = await this.client.get<User>(`/users/${id}`);
      return { success: true, data: response.data };
    } catch (error) {
      return {
        success: false,
        error: "Failed to fetch user",
        code: "USER_NOT_FOUND"
      };
    }
  }

  async createUser(user: UserCreate): Promise<ApiResponse<User>> {
    try {
      const response = await this.client.post<User>("/users", user);
      return { success: true, data: response.data };
    } catch (error) {
      return {
        success: false,
        error: "Failed to create user",
        code: "VALIDATION_ERROR"
      };
    }
  }
}

export const userService = new UserService();
```

### React Hook Pattern
```typescript
// hooks/useUsers.ts
import { useState, useEffect, useCallback } from "react";
import { User, PaginatedResponse } from "@/types/user";
import { userService } from "@/lib/api";

export function useUsers(page: number = 1) {
  const [data, setData] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchUsers = useCallback(async () => {
    try {
      setLoading(true);
      const response = await userService.listUsers(page);
      setData(response.data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
    } finally {
      setLoading(false);
    }
  }, [page]);

  useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  return { data, loading, error, refetch: fetchUsers };
}
```

## Configuration Patterns

### Environment Configuration
```python
# config.py
from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    ENV: str = "development"

    # Database
    DATABASE_URL: str
    DATABASE_POOL_SIZE: int = 20
    DATABASE_ECHO: bool = False

    # Security
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # External APIs
    EXTERNAL_API_KEY: Optional[str] = None
    EXTERNAL_API_URL: str = "https://api.example.com"

    class Config:
        env_file = ".env"
        case_sensitive = True

    @property
    def is_production(self) -> bool:
        return self.ENV == "production"

settings = Settings()
```

## Summary

This guide provides battle-tested patterns for:
- REST API design with proper error handling
- Comprehensive testing with pytest and fixtures
- Production-grade Docker configurations
- CI/CD automation with GitHub Actions
- Asynchronous Python with proper concurrency
- TypeScript with type safety and API integration

Reference these patterns when designing new features or reviewing implementations.
