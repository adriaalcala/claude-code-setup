---
name: refactor-analyzer
description: "Analyze code for refactoring opportunities with impact/effort scoring. Detects code smells, complexity hotspots, duplication, tight coupling. Trigger on 'refactor', 'code smells', 'technical debt', 'simplify', 'reduce complexity'."
---

# Refactor Analyzer Skill

## Overview
Systematically identify refactoring opportunities, prioritize by impact/effort ratio, and provide step-by-step refactoring plans with before/after examples.

## Phase 1: SCAN
Analyze code for antipatterns and complexity indicators:

### Cyclomatic Complexity
- Install: `pip install radon`
- Scan: `radon cc -s src/` — score each function
- Flag: functions with CC > 10 (very high)
- Target: reduce to CC < 5

### Code Duplication
- Look for: copy-pasted blocks (>10 lines)
- Commands: `radon mi src/` — maintainability index
- Manual scan: identical if/else branches, repeated loops, similar class structures

### Long Functions
- Flag: functions > 50 lines
- Action: extract helper functions
- Target: average function length < 30 lines

### Deep Nesting
- Count: nesting depth in if/for/while
- Flag: depth > 3 levels
- Refactoring: early returns, guard clauses, helper functions

### Large Files
- Flag: files > 300 lines
- Action: split into modules/classes
- Analysis: identify logical groupings

### God Classes
- Characteristics:
  - Multiple responsibilities (doing too much)
  - High method count (>20 methods)
  - Large state (>10 fields)
  - Difficult to test individual parts
- Symptom: class name doesn't match main responsibility

### Tight Coupling
- Red flags:
  - Imports from many modules
  - Passing entire objects when only 1-2 fields used
  - Circular dependencies
  - Mock many dependencies in tests
- Analysis: dependency graph visualization

### Other Smells
- Long parameter lists (>5 params)
- Magic numbers/strings (use named constants)
- Feature envy (using many methods from another class)
- Divergent change (change for multiple reasons)
- Comments explaining "what" (should be obvious from code)

## Phase 2: CLASSIFY
Map findings to refactoring patterns:

### Extraction Patterns
- **Extract Method**: Long function to multiple small functions
- **Extract Class**: God class split into focused classes
- **Extract Constant**: Magic numbers to named constant
- **Extract Variable**: Complex expression to readable temp var

### Simplification Patterns
- **Simplify Conditional**: Nested if to guard clause, ternary, switch
- **Replace Parameter with Method**: Passing derived value computed in function
- **Remove Parameter**: Function doesn't use parameter
- **Introduce Parameter Object**: Many params bundled into class

### Redesign Patterns
- **Replace Inheritance with Delegation**: Tight coupling via inheritance to composition
- **Introduce Strategy Pattern**: Multiple algorithms with if/else to strategy objects
- **Replace Enum with Polymorphism**: Enum with switch to subclasses with override
- **Extract Interface**: High coupling depends on interface not class

### Organization Patterns
- **Move Method**: Method in wrong class moved to class that uses it
- **Move Field**: Field accessed more by other class
- **Inline Class**: Useless class with 1-2 methods merged into other class
- **Rename**: Misleading name clarified with better name

## Phase 3: PRIORITIZE
Score each opportunity by Impact and Effort:

### Impact Score (1-10)
- Complexity reduction: how many functions simplified?
- Maintainability: easier to change/extend?
- Test coverage: easier to test?
- Coupling reduction: fewer dependencies?
- Reusability: code can be shared?

### Effort Score (1-10)
- Lines to change: 1-50 = 2, 50-200 = 5, 200+ = 8
- Dependencies affected: changes in 1 file = 2, 3+ files = 6
- Risk: low = 0, medium = +3, high = +5
- Testing effort: simple = 1, integration tests = 3, complex = 5

### Priority Calculation
Priority = Impact / Effort
Risk adjustment: if Risk > 6, multiply by 0.5

### Categorization
- **Quick Wins**: Priority > 3 (do first)
- **Important**: Priority 1-3 (significant value)
- **Maintenance**: Priority < 1 (nice to have)

## Phase 4: PLAN
Top 5 opportunities with step-by-step plan:

For each refactoring:
1. **Name**: Clear description
2. **Current State**: Before code snippet
3. **Problem**: What's bad about current state
4. **Refactoring Steps** (numbered):
   - Step 1: [action]
   - Step 2: [action]
   - Step 3: [run tests]
5. **Target State**: After code snippet
6. **Benefits**: Specific improvements
7. **Risk**: Any gotchas or edge cases
8. **Test Plan**: How to verify correctness
9. **Effort Estimate**: hours/days
10. **Priority**: Quick Win / Important / Maintenance

## Local-First Analysis
Use Ollama for initial code smell detection:

```bash
ollama run qwen3-coder << 'PROMPT'
Analyze this Python/TypeScript code for refactoring opportunities.
Look for: long functions, duplication, complexity, god classes, tight coupling.
Format as JSON with: file, function_name, smell_type, severity (1-10), suggestion.

[CODE SNIPPET]
PROMPT
```

Benefits:
- Fast local execution vs cloud API
- No code leaves your server
- Iterative refinement with follow-up prompts
- Use output to guide manual detailed analysis

Then perform detailed analysis with radon, manual code review, and structured refactoring plans.

## Example Workflow

### Scan
```bash
radon cc -s src/auth.py
# Output: auth.py:verify_token cc=12
radon mi src/
# Output: Maintainability Index = 65 (Medium)
```

### Analyze with Ollama
```bash
ollama run qwen3-coder << 'EOF'
I'm seeing high complexity in my verify_token function (CC=12).
Here's the code: [PASTE 50 LINES]
What refactoring would help most?
EOF
```

### Create Plan
Extract nested conditions into helper functions:
- check_expiry(token)
- validate_signature(token)
- verify_permissions(token, required_perms)

Then refactor verify_token to call these helpers.

