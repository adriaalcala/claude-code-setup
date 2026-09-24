---
paths:
  - "**/*.py"
  - "pyproject.toml"
  - "uv.lock"
  - "requirements.txt"
---
# Python Code Conventions

Project-specific Python coding standards and guidelines.

## File Structure

```
project_root/
├── src/
│   ├── __init__.py
│   ├── main.py
│   ├── config.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── product.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── user_service.py
│   │   └── product_service.py
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes/
│   │   │   ├── __init__.py
│   │   │   ├── users.py
│   │   │   └── products.py
│   │   └── middleware.py
│   └── utils/
│       ├── __init__.py
│       ├── validators.py
│       └── helpers.py
├── tests/
│   ├── __init__.py
│   ├── test_models.py
│   ├── test_services.py
│   ├── unit/
│   │   ├── __init__.py
│   │   └── test_validators.py
│   └── integration/
│       ├── __init__.py
│       └── test_api.py
├── docs/
├── pyproject.toml
├── requirements.txt
└── README.md
```

## Naming Conventions

### Modules and Packages
- Use lowercase with underscores: `user_service.py`, `auth_middleware.py`
- Single words preferred: `models/`, `services/`, `utils/`
- No hyphens or mixed case

### Classes
- PascalCase: `UserService`, `ProductModel`, `AuthenticationError`
- Base classes: `BasePersistence`, `BaseRepository`
- Exceptions: `UserNotFoundError`, `ValidationError`

### Functions and Methods
- snake_case: `get_user()`, `create_product()`, `validate_email()`
- Private methods: `_internal_method()`
- Magic methods: `__init__()`, `__str__()`

### Variables and Constants
- Variables: snake_case: `user_count`, `is_active`, `config`
- Constants: UPPER_CASE: `MAX_RETRIES`, `DEFAULT_TIMEOUT`
- Private: `_internal_state`

### Booleans
- Prefix with `is_`, `has_`, `can_`:
  ```python
  is_active = True
  has_permission = False
  can_delete = user.is_admin
  ```

## Import Organization

**Order:**
1. Standard library imports
2. Third-party imports
3. Local imports

**Separate with blank lines**

```python
# Standard library
import os
import sys
from pathlib import Path
from typing import Optional, List, Dict

# Third-party
import fastapi
from sqlalchemy import Column, String, Integer
import pydantic

# Local
from .models import User
from .services import UserService
from ..utils import validators
```

**Avoid:**
- `from module import *`
- Circular imports
- Importing at function level (except lazy loading)

## Type Hints

**Always use type hints for:**
- Function parameters
- Return types
- Class attributes

```python
from typing import Optional, List, Dict, Union, Tuple

class UserService:
    def __init__(self, db: Database) -> None:
        self.db = db

    def get_user(self, user_id: int) -> Optional[User]:
        """Get user by ID or return None if not found."""
        return self.db.query(User).filter(User.id == user_id).first()

    def create_users(self, data: List[Dict[str, str]]) -> List[User]:
        """Create multiple users."""
        users = [User(**item) for item in data]
        self.db.add_all(users)
        self.db.commit()
        return users

    def update_user(
        self,
        user_id: int,
        name: Optional[str] = None,
        email: Optional[str] = None
    ) -> User:
        """Update user fields."""
        user = self.get_user(user_id)
        if name:
            user.name = name
        if email:
            user.email = email
        self.db.commit()
        return user
```

## Docstrings

Use Google-style docstrings:

```python
def calculate_total_price(
    items: List[Dict[str, float]],
    tax_rate: float = 0.1
) -> float:
    """Calculate total price including tax.

    Args:
        items: List of items with 'price' key
        tax_rate: Tax rate as decimal (default 0.1 = 10%)

    Returns:
        Total price including tax

    Raises:
        ValueError: If items list is empty
        KeyError: If item missing 'price' key

    Example:
        >>> items = [{'price': 10.0}, {'price': 20.0}]
        >>> calculate_total_price(items)
        33.0
    """
    if not items:
        raise ValueError("Items list cannot be empty")

    subtotal = sum(item['price'] for item in items)
    return subtotal * (1 + tax_rate)
```

## Code Style

### Line Length
- Maximum 100 characters
- 88 characters for readability preference

### Indentation
- 4 spaces (never tabs)
- Consistent throughout project

### Blank Lines
- 2 blank lines between top-level definitions
- 1 blank line between method definitions

```python
class UserService:

    def __init__(self) -> None:
        pass

    def get_user(self) -> User:
        pass

    def create_user(self) -> User:
        pass


class ProductService:

    def get_product(self) -> Product:
        pass
```

### String Formatting
Prefer f-strings:

```python
# Good
name = "Alice"
message = f"Hello, {name}!"

# Avoid
message = "Hello, {}!".format(name)
message = "Hello, %s!" % name
```

## Error Handling

### Custom Exceptions
```python
class APIError(Exception):
    """Base API exception."""
    def __init__(self, code: str, message: str, status_code: int = 400):
        self.code = code
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class ValidationError(APIError):
    """Validation error."""
    def __init__(self, message: str, field: Optional[str] = None):
        super().__init__("VALIDATION_ERROR", message, 422)
        self.field = field


class NotFoundError(APIError):
    """Resource not found."""
    def __init__(self, resource: str, identifier: str):
        message = f"{resource} {identifier} not found"
        super().__init__("NOT_FOUND", message, 404)
```

### Try/Except Blocks
```python
# Good: Specific exception handling
try:
    user = get_user(user_id)
except UserNotFoundError:
    logger.warning(f"User {user_id} not found")
    return None
except DatabaseError as e:
    logger.error(f"Database error: {e}")
    raise

# Avoid: Too broad
try:
    user = get_user(user_id)
except:
    pass
```

## Testing Conventions

```python
# tests/unit/test_user_service.py
import pytest
from unittest.mock import Mock, patch
from services.user_service import UserService
from models import User

class TestUserService:
    """Tests for UserService."""

    @pytest.fixture
    def service(self):
        """Create service with mock database."""
        db = Mock()
        return UserService(db)

    def test_get_user_returns_user(self, service):
        """Test getting existing user."""
        service.db.query.return_value.filter.return_value.first.return_value = User(
            id=1, name="Alice"
        )

        user = service.get_user(1)

        assert user.id == 1
        assert user.name == "Alice"

    def test_get_user_returns_none_when_not_found(self, service):
        """Test getting non-existent user."""
        service.db.query.return_value.filter.return_value.first.return_value = None

        user = service.get_user(999)

        assert user is None

    @pytest.mark.parametrize("user_id", [0, -1, None])
    def test_get_user_rejects_invalid_ids(self, service, user_id):
        """Test invalid user IDs."""
        with pytest.raises(ValueError):
            service.get_user(user_id)
```

## Async/Await

```python
import asyncio
from typing import Coroutine

async def fetch_user(user_id: int) -> User:
    """Fetch user asynchronously."""
    await asyncio.sleep(0.1)  # Simulated I/O
    return User(id=user_id)

async def fetch_multiple_users(user_ids: List[int]) -> List[User]:
    """Fetch multiple users concurrently."""
    tasks = [fetch_user(uid) for uid in user_ids]
    return await asyncio.gather(*tasks)

async def retry_on_failure(
    coro: Coroutine,
    max_retries: int = 3,
    delay: int = 1
) -> Any:
    """Retry coroutine with exponential backoff."""
    for attempt in range(max_retries):
        try:
            return await coro
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            await asyncio.sleep(delay * (2 ** attempt))
```

## Configuration

```python
# config.py
from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    """Application settings."""

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    DEBUG: bool = False

    # Database
    DATABASE_URL: str
    DATABASE_POOL_SIZE: int = 20

    # Security
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    class Config:
        env_file = ".env"
        case_sensitive = True

    @property
    def is_production(self) -> bool:
        """Check if running in production."""
        return not self.DEBUG


settings = Settings()
```

## Linting and Formatting

### Tools
- **ruff**: Fast Python linter and formatter
- **mypy**: Static type checker
- **pytest**: Testing framework

### Configuration (pyproject.toml)
```toml
[tool.ruff]
line-length = 100
target-version = "py311"

[tool.mypy]
python_version = "3.11"
strict = true
warn_unused_ignores = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
addopts = "--strict-markers -v"
```

## Common Patterns

### Repository Pattern
```python
from abc import ABC, abstractmethod

class BaseRepository(ABC):
    """Base repository for database access."""

    @abstractmethod
    def get(self, id: int) -> Optional[Any]:
        pass

    @abstractmethod
    def create(self, **kwargs) -> Any:
        pass

    @abstractmethod
    def update(self, id: int, **kwargs) -> Any:
        pass

    @abstractmethod
    def delete(self, id: int) -> bool:
        pass


class UserRepository(BaseRepository):
    """User repository."""

    def __init__(self, session: Session):
        self.session = session

    def get(self, id: int) -> Optional[User]:
        return self.session.query(User).filter(User.id == id).first()

    def create(self, **kwargs) -> User:
        user = User(**kwargs)
        self.session.add(user)
        self.session.commit()
        return user
```

### Dependency Injection
```python
from typing import Annotated
from fastapi import Depends

class UserService:
    def __init__(self, db: Database):
        self.db = db


def get_user_service(db: Database = Depends(get_db)) -> UserService:
    return UserService(db)


@router.get("/users/{user_id}")
async def get_user(
    user_id: int,
    service: Annotated[UserService, Depends(get_user_service)]
):
    return service.get_user(user_id)
```

## Checklist for New Code

- [ ] Type hints on all functions
- [ ] Docstrings for public methods
- [ ] Tests for new functionality
- [ ] No bare except clauses
- [ ] No print statements (use logging)
- [ ] Follows naming conventions
- [ ] Passes ruff/mypy checks
- [ ] No circular imports
- [ ] Handles errors explicitly
