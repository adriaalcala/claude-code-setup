---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "package.json"
  - "tsconfig.json"
---
# TypeScript Code Conventions

Project-specific TypeScript coding standards and guidelines.

## File Structure

```
project_root/
├── src/
│   ├── index.ts
│   ├── types/
│   │   ├── user.ts
│   │   ├── product.ts
│   │   └── api.ts
│   ├── models/
│   │   ├── User.ts
│   │   └── Product.ts
│   ├── services/
│   │   ├── UserService.ts
│   │   └── ProductService.ts
│   ├── api/
│   │   ├── routes/
│   │   │   ├── users.ts
│   │   │   └── products.ts
│   │   ├── middleware/
│   │   │   └── auth.ts
│   │   └── handlers/
│   │       └── errorHandler.ts
│   ├── utils/
│   │   ├── validators.ts
│   │   ├── helpers.ts
│   │   └── logger.ts
│   └── config/
│       └── settings.ts
├── tests/
│   ├── unit/
│   │   ├── services/
│   │   │   └── UserService.test.ts
│   │   └── utils/
│   │       └── validators.test.ts
│   └── integration/
│       └── api.test.ts
├── tsconfig.json
├── package.json
└── README.md
```

## Naming Conventions

### Files and Directories
- PascalCase for components/classes: `UserService.ts`, `AuthMiddleware.ts`
- camelCase for utilities: `validators.ts`, `helpers.ts`
- Use descriptive names: `errorHandler.ts`, not `error.ts`

### Classes and Interfaces
- PascalCase: `UserService`, `ProductModel`, `AuthenticationError`
- Interfaces: `IUser`, `IProduct` (or without I if preferred)
- Abstract classes: `BaseRepository`, `BasePersistence`

### Types and Enums
- PascalCase: `UserStatus`, `APIResponse<T>`, `ErrorCode`
- Enum values: UPPER_CASE: `Status.ACTIVE`, `Role.ADMIN`

### Functions and Methods
- camelCase: `getUser()`, `createProduct()`, `validateEmail()`
- Private methods: `_internalMethod()`
- Async functions: `async fetchUser()`, `async createUser()`

### Variables and Constants
- Variables: camelCase: `userName`, `isActive`, `config`
- Constants: UPPER_CASE: `MAX_RETRIES`, `DEFAULT_TIMEOUT`
- Private: `_internalState`

### Booleans
- Prefix with `is`, `has`, `can`:
  ```typescript
  const isActive = true;
  const hasPermission = false;
  const canDelete = user.isAdmin;
  ```

## Type System

### Basic Types
```typescript
// Primitives
let name: string = "Alice";
let age: number = 30;
let isActive: boolean = true;
let nothing: null = null;
let undefined_value: undefined = undefined;

// Arrays
const numbers: number[] = [1, 2, 3];
const users: Array<User> = [];

// Union types
type Status = "active" | "inactive" | "pending";
const status: Status = "active";

// Optional
let optional: string | undefined = undefined;
let optional2?: string;  // Shorthand
```

### Interfaces
```typescript
interface User {
  id: number;
  name: string;
  email: string;
  age?: number;  // Optional
  readonly createdAt: Date;  // Readonly
}

interface Timestamped {
  createdAt: Date;
  updatedAt: Date;
}

// Extending interfaces
interface AdminUser extends User, Timestamped {
  role: "admin" | "moderator";
}

// Function types
interface UserValidator {
  (user: User): boolean;
}

const isValidUser: UserValidator = (user) => {
  return user.id > 0 && user.email.includes("@");
};
```

### Generics
```typescript
// Generic function
function getItem<T>(id: number, items: T[]): T | undefined {
  return items.find(item => (item as any).id === id);
}

// Generic interface
interface Repository<T> {
  get(id: number): Promise<T | null>;
  create(data: T): Promise<T>;
  update(id: number, data: Partial<T>): Promise<T>;
  delete(id: number): Promise<boolean>;
}

// Generic class
class BaseRepository<T> implements Repository<T> {
  constructor(private items: T[]) {}

  get(id: number): Promise<T | null> {
    return Promise.resolve((this.items[id as any] as any) || null);
  }

  create(data: T): Promise<T> {
    this.items.push(data);
    return Promise.resolve(data);
  }

  update(id: number, data: Partial<T>): Promise<T> {
    return Promise.resolve({ ...this.items[id as any], ...data } as T);
  }

  delete(id: number): Promise<boolean> {
    this.items.splice(id as any, 1);
    return Promise.resolve(true);
  }
}
```

## Import/Export Organization

### Order
1. Third-party imports
2. Relative imports
3. Type imports

```typescript
// Third-party
import express, { Router, Request, Response } from "express";
import { z } from "zod";
import axios from "axios";

// Relative
import { UserService } from "./services/UserService";
import { UserRepository } from "./repositories/UserRepository";
import { errorHandler } from "./utils/errorHandler";

// Types
import type { User, APIResponse } from "./types";
import type { Request as ExpressRequest } from "express";
```

### Avoid
- Circular imports
- Default exports (use named exports)
- Importing entire modules as `import *`

## Async/Await

```typescript
async function fetchUser(userId: number): Promise<User> {
  const response = await fetch(`/api/users/${userId}`);
  if (!response.ok) {
    throw new Error("User not found");
  }
  return response.json();
}

async function fetchMultipleUsers(userIds: number[]): Promise<User[]> {
  const promises = userIds.map(id => fetchUser(id));
  return Promise.all(promises);
}

async function retryOnFailure<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  delay: number = 1000
): Promise<T> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === maxRetries) throw error;
      await new Promise(resolve => setTimeout(resolve, delay * attempt));
    }
  }
  throw new Error("Failed after retries");
}
```

## Error Handling

### Custom Errors
```typescript
class APIError extends Error {
  constructor(
    public code: string,
    public message: string,
    public statusCode: number = 400
  ) {
    super(message);
    Object.setPrototypeOf(this, APIError.prototype);
  }
}

class ValidationError extends APIError {
  constructor(message: string, public field?: string) {
    super("VALIDATION_ERROR", message, 422);
    Object.setPrototypeOf(this, ValidationError.prototype);
  }
}

class NotFoundError extends APIError {
  constructor(resource: string, identifier: string) {
    super(
      "NOT_FOUND",
      `${resource} ${identifier} not found`,
      404
    );
    Object.setPrototypeOf(this, NotFoundError.prototype);
  }
}

// Usage
throw new NotFoundError("User", "123");
```

### Try/Catch
```typescript
// Good: Specific error handling
try {
  const user = await fetchUser(userId);
  return user;
} catch (error) {
  if (error instanceof NotFoundError) {
    logger.warn(`User ${userId} not found`);
    return null;
  } else if (error instanceof APIError) {
    logger.error(`API error: ${error.message}`);
    throw error;
  } else {
    logger.error("Unexpected error", { error });
    throw new Error("Internal server error");
  }
}
```

## Class-Based Components

```typescript
class UserService {
  private repository: UserRepository;

  constructor(repository: UserRepository) {
    this.repository = repository;
  }

  async getUser(userId: number): Promise<User | null> {
    return this.repository.get(userId);
  }

  async createUser(data: Omit<User, "id">): Promise<User> {
    // Validation
    if (!data.email.includes("@")) {
      throw new ValidationError("Invalid email", "email");
    }

    // Create
    return this.repository.create(data);
  }

  async updateUser(
    userId: number,
    data: Partial<User>
  ): Promise<User> {
    const user = await this.getUser(userId);
    if (!user) {
      throw new NotFoundError("User", userId.toString());
    }

    return this.repository.update(userId, data);
  }

  async deleteUser(userId: number): Promise<boolean> {
    return this.repository.delete(userId);
  }
}
```

## API Request/Response Types

```typescript
// types/api.ts
export interface APIResponse<T> {
  success: true;
  data: T;
}

export interface APIError {
  success: false;
  error: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
  };
}

export type APIResult<T> = APIResponse<T> | APIError;

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
  };
}

// Usage
async function listUsers(page: number = 1): Promise<APIResult<User[]>> {
  try {
    const response = await fetch(`/api/users?page=${page}`);
    const data = await response.json();
    return { success: true, data };
  } catch (error) {
    return {
      success: false,
      error: {
        code: "LIST_USERS_FAILED",
        message: "Failed to fetch users"
      }
    };
  }
}
```

## Testing

```typescript
// tests/unit/services/UserService.test.ts
import { describe, it, expect, beforeEach, vi } from "vitest";
import { UserService } from "../../../src/services/UserService";
import type { UserRepository } from "../../../src/repositories/UserRepository";

describe("UserService", () => {
  let service: UserService;
  let mockRepository: UserRepository;

  beforeEach(() => {
    mockRepository = {
      get: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      delete: vi.fn()
    } as any;

    service = new UserService(mockRepository);
  });

  describe("getUser", () => {
    it("should return user when found", async () => {
      const user = { id: 1, name: "Alice", email: "alice@example.com" };
      vi.mocked(mockRepository.get).mockResolvedValue(user);

      const result = await service.getUser(1);

      expect(result).toEqual(user);
      expect(mockRepository.get).toHaveBeenCalledWith(1);
    });

    it("should return null when not found", async () => {
      vi.mocked(mockRepository.get).mockResolvedValue(null);

      const result = await service.getUser(999);

      expect(result).toBeNull();
    });
  });

  describe("createUser", () => {
    it("should create user with valid data", async () => {
      const data = { name: "Bob", email: "bob@example.com" };
      const user = { id: 2, ...data };
      vi.mocked(mockRepository.create).mockResolvedValue(user);

      const result = await service.createUser(data);

      expect(result).toEqual(user);
      expect(mockRepository.create).toHaveBeenCalledWith(data);
    });

    it("should throw error with invalid email", async () => {
      const data = { name: "Charlie", email: "invalid" };

      await expect(service.createUser(data)).rejects.toThrow(
        "Invalid email"
      );
    });
  });
});
```

## Configuration

```typescript
// src/config/settings.ts
import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  PORT: z.coerce.number().default(3000),
  HOST: z.string().default("0.0.0.0"),
  API_URL: z.string().url(),
  DATABASE_URL: z.string(),
  SECRET_KEY: z.string(),
  LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info"),
});

type Env = z.infer<typeof envSchema>;

const env: Env = envSchema.parse(process.env);

export const config = {
  env,
  isDevelopment: env.NODE_ENV === "development",
  isProduction: env.NODE_ENV === "production",
  isTest: env.NODE_ENV === "test"
} as const;
```

## Code Style

### Line Length
- Maximum 100 characters
- Use line breaks for readability

### Indentation
- 2 spaces (TypeScript convention)
- Consistent throughout project

### String Formatting
Prefer template literals:

```typescript
// Good
const name = "Alice";
const message = `Hello, ${name}!`;

// Avoid
const message = "Hello, " + name + "!";
```

## Linting and Formatting

### Tools
- **ESLint**: Linting
- **Prettier**: Formatting
- **TypeScript**: Type checking
- **Vitest**: Testing

### Configuration (tsconfig.json)
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "lib": ["ES2020"],
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

## Checklist for New Code

- [ ] All types properly annotated
- [ ] Interfaces for data structures
- [ ] Generics used appropriately
- [ ] Error handling with specific types
- [ ] Tests for new functionality
- [ ] No any types (unless necessary)
- [ ] Follows naming conventions
- [ ] Passes ESLint checks
- [ ] No circular imports
- [ ] Proper async/await usage
