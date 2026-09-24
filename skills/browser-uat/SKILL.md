---
name: Browser UAT
description: |
  Run User Acceptance Tests against a real Chrome browser using Playwright via CDP.
  Use this skill when the user asks to test a web page, verify UI behavior, check that
  a feature works in the browser, run UAT, do browser testing, or validate a web flow.
  Also trigger when the user mentions: "test the page", "check if the button works",
  "verify the login flow", "browser test", "UI test", "e2e test", "acceptance test".
triggers:
  - "test the page"
  - "browser test"
  - "UAT"
  - "acceptance test"
  - "verify the login"
  - "check the UI"
  - "e2e test"
  - "test in chrome"
  - "run browser test"
---

# Browser UAT — Real Chrome Testing via CDP

This skill enables you to run User Acceptance Tests against the user's actual Chrome browser
(with real sessions, cookies, and auth tokens) using Playwright connected via Chrome DevTools Protocol.

## Architecture

```
User describes test in natural language
  → You generate a test steps JSON
  → run-test.js connects to Chrome via CDP
  → Executes each step (navigate, click, fill, assert)
  → Screenshots on failure
  → You present a markdown report
```

## Prerequisites

- Chrome running with `--remote-debugging-port` (user launches with `chrome-debug <profile>`)
- Playwright installed: `cd ~/.claude/skills/browser-uat/scripts && npm install`
- Profile config: `~/.claude/skills/browser-uat/configs/profiles.json`

## Step 1: Check Profile Configuration

Read the profiles config to know which profiles are available:

```bash
cat ~/.claude/skills/browser-uat/configs/profiles.json
```

This returns a JSON object mapping profile names to ports and base URLs.

## Step 2: Verify Chrome Connection

Before running tests, check that Chrome is running with debugging enabled:

```bash
node ~/.claude/skills/browser-uat/scripts/check-connection.js <port>
```

If not connected, tell the user to run:
```bash
chrome-debug <profile-name>
```

## Step 3: Generate Test Steps

Translate the user's natural language test description into a JSON test definition.

### Supported Actions

| Action | Parameters | Description |
|--------|-----------|-------------|
| `goto` | `url` | Navigate to URL (relative to baseUrl or absolute) |
| `fill` | `selector`, `value` | Type into an input field |
| `click` | `selector` | Click an element |
| `waitForSelector` | `selector`, `state?`, `timeout?` | Wait for element (default: visible) |
| `waitForURL` | `url`, `timeout?` | Wait for navigation to URL |
| `assertVisible` | `selector` | Assert element is visible |
| `assertText` | `selector`, `expected` | Assert element contains text |
| `assertCount` | `selector`, `min?`, `max?`, `exact?` | Assert number of matching elements |
| `screenshot` | `name`, `fullPage?` | Capture screenshot |
| `wait` | `ms` | Explicit wait in milliseconds |
| `evaluate` | `script` | Run JavaScript in page context |
| `selectOption` | `selector`, `value` | Select dropdown option |
| `check` | `selector` | Check a checkbox |
| `uncheck` | `selector` | Uncheck a checkbox |
| `hover` | `selector` | Hover over element |
| `press` | `selector?`, `key` | Press keyboard key |

### Selector Strategy

Prefer selectors in this order:
1. Text-based: `button:has-text('Save')`, `a:has-text('Login')`
2. Role-based: `role=button[name="Submit"]`
3. Placeholder: `input[placeholder="Email"]`
4. Name/type: `input[name="email"]`, `input[type="password"]`
5. Test IDs: `[data-testid="campaign-table"]`
6. CSS: `.campaign-row`, `#login-form`

### Environment Variables in Values

Values starting with `$` are resolved from environment variables:
- `"$STAGING_USER"` → reads `process.env.STAGING_USER`
- `"$STAGING_PASSWORD"` → reads `process.env.STAGING_PASSWORD`

Add test credentials to `~/.secrets.zsh`:
```bash
export STAGING_USER="user@example.com"
export STAGING_PASSWORD="your-staging-password"
```

## Step 4: Run the Test

Execute the test with run-test.js:

```bash
node ~/.claude/skills/browser-uat/scripts/run-test.js '<JSON test definition>'
```

### Example Test Definition

```json
{
  "cdpUrl": "http://localhost:9222",
  "baseUrl": "https://app.example.com",
  "screenshotDir": "/tmp/uat-screenshots",
  "timeout": 5000,
  "steps": [
    { "action": "goto", "url": "/login" },
    { "action": "fill", "selector": "input[name=email]", "value": "$STAGING_USER" },
    { "action": "fill", "selector": "input[type=password]", "value": "$STAGING_PASSWORD" },
    { "action": "click", "selector": "button:has-text('Log in')" },
    { "action": "waitForURL", "url": "/dashboard" },
    { "action": "goto", "url": "/campaigns" },
    { "action": "waitForSelector", "selector": "table" },
    { "action": "assertVisible", "selector": "th:has-text('Active')" },
    { "action": "assertCount", "selector": "tbody tr", "min": 1 },
    { "action": "screenshot", "name": "campaigns-loaded" }
  ]
}
```

## Step 5: Present Results

The runner outputs JSON. Present it as a markdown report:

```markdown
# UAT Report: [Test Name]

**Profile:** [profile] (port [port])
**Base URL:** [baseUrl]
**Status:** ✅ PASSED (N/N steps) | ❌ FAILED at step N
**Duration:** X.Xs

## Steps
1. ✅ Navigate to /login (0.8s)
2. ✅ Fill email field (0.1s)
...
N. ❌ Verify table — Element not found: table (5.0s)
   Screenshot: /tmp/uat-screenshots/failure-step-N.png

## Screenshots
- [List captured screenshots with paths]
```

If the user is in a context where they can view images, show the failure screenshot.

## Common Test Patterns

### Login Flow
```json
[
  { "action": "goto", "url": "/login" },
  { "action": "fill", "selector": "input[name=email]", "value": "$STAGING_USER" },
  { "action": "fill", "selector": "input[type=password]", "value": "$STAGING_PASSWORD" },
  { "action": "click", "selector": "button:has-text('Log in')" },
  { "action": "waitForURL", "url": "/dashboard", "timeout": 10000 }
]
```

### Table Verification
```json
[
  { "action": "goto", "url": "/campaigns" },
  { "action": "waitForSelector", "selector": "table", "timeout": 10000 },
  { "action": "assertCount", "selector": "tbody tr", "min": 1 },
  { "action": "assertVisible", "selector": "th:has-text('Status')" }
]
```

### Form Submission
```json
[
  { "action": "goto", "url": "/settings" },
  { "action": "fill", "selector": "input[name=company]", "value": "Example Corp" },
  { "action": "selectOption", "selector": "select[name=timezone]", "value": "Europe/London" },
  { "action": "check", "selector": "input[name=notifications]" },
  { "action": "click", "selector": "button:has-text('Save')" },
  { "action": "waitForSelector", "selector": ".toast-success" },
  { "action": "screenshot", "name": "settings-saved" }
]
```

### Navigation Check
```json
[
  { "action": "goto", "url": "/" },
  { "action": "click", "selector": "a:has-text('Reports')" },
  { "action": "waitForURL", "url": "/reports" },
  { "action": "assertVisible", "selector": "h1:has-text('Reports')" }
]
```

## Troubleshooting

### "Cannot connect to Chrome"
Chrome is not running with debugging enabled. Tell the user:
```bash
chrome-debug <profile-name>
```

### "Element not found" / Timeout
- The selector might be wrong — ask the user to describe the element
- The page might not have loaded — add a `waitForSelector` step before asserting
- Increase timeout for slow pages: `"timeout": 10000`

### Wrong profile
- Check which profiles are configured: `chrome-debug --list`
- Verify the port matches: `node check-connection.js <port>`

### Screenshots not capturing
- Verify the screenshot directory exists and is writable
- Default: `/tmp/uat-screenshots`

## Important Notes

- Tests run against the user's REAL browser with real sessions and cookies
- The runner creates a new tab for testing and closes it when done
- It does NOT close or restart Chrome
- Environment variables in values (e.g., `$STAGING_PASSWORD`) are resolved at runtime
- Always check the connection before running tests
- On failure, execution stops at the failing step and captures a screenshot
