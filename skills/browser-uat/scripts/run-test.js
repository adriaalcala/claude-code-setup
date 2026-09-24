#!/usr/bin/env node
// run-test.js — Execute UAT test steps against Chrome via CDP
//
// Usage: node run-test.js '<JSON test definition>'
//
// Input JSON format:
// {
//   "cdpUrl": "http://localhost:9222",
//   "baseUrl": "https://app.example.com",
//   "screenshotDir": "/tmp/uat-screenshots",
//   "timeout": 5000,
//   "steps": [
//     { "action": "goto", "url": "/login" },
//     { "action": "fill", "selector": "input[name=email]", "value": "user@example.com" },
//     { "action": "click", "selector": "button:has-text('Login')" },
//     { "action": "waitForSelector", "selector": "table" },
//     { "action": "assertVisible", "selector": ".dashboard" },
//     { "action": "screenshot", "name": "result" }
//   ]
// }

import { chromium } from 'playwright';
import { mkdirSync, existsSync } from 'fs';
import { resolve } from 'path';

// Parse input
const input = process.argv[2];
if (!input) {
  console.error('Usage: node run-test.js \'<JSON test definition>\'');
  process.exit(1);
}

let testDef;
try {
  testDef = JSON.parse(input);
} catch (e) {
  console.error(`Invalid JSON input: ${e.message}`);
  process.exit(1);
}

const {
  cdpUrl = 'http://localhost:9222',
  baseUrl = '',
  screenshotDir = '/tmp/uat-screenshots',
  timeout = 5000,
  steps = [],
  reuseExistingPage = false,
} = testDef;

// Ensure screenshot directory exists
if (!existsSync(screenshotDir)) {
  mkdirSync(screenshotDir, { recursive: true });
}

// Resolve env vars in values (e.g., "$STAGING_PASSWORD")
function resolveEnvVars(value) {
  if (typeof value !== 'string') return value;
  return value.replace(/\$([A-Z_][A-Z0-9_]*)/g, (_, name) => process.env[name] || '');
}

// Build full URL from relative path
function resolveUrl(url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  return `${baseUrl.replace(/\/$/, '')}${url.startsWith('/') ? '' : '/'}${url}`;
}

// Execute a single test step
async function executeStep(page, step, index) {
  const startTime = Date.now();
  const { action } = step;

  try {
    switch (action) {
      case 'goto': {
        const url = resolveUrl(step.url);
        await page.goto(url, { timeout, waitUntil: 'domcontentloaded' });
        break;
      }

      case 'fill': {
        const value = resolveEnvVars(step.value);
        await page.fill(step.selector, value, { timeout });
        break;
      }

      case 'click': {
        await page.click(step.selector, { timeout });
        break;
      }

      case 'waitForSelector': {
        await page.waitForSelector(step.selector, {
          timeout: step.timeout || timeout,
          state: step.state || 'visible',
        });
        break;
      }

      case 'waitForURL': {
        const url = step.url.startsWith('http') ? step.url : `**${step.url}**`;
        await page.waitForURL(url, { timeout: step.timeout || timeout });
        break;
      }

      case 'assertVisible': {
        const el = await page.waitForSelector(step.selector, { timeout, state: 'visible' });
        if (!el) throw new Error(`Element not visible: ${step.selector}`);
        break;
      }

      case 'assertText': {
        const el = await page.waitForSelector(step.selector, { timeout, state: 'visible' });
        const text = await el.textContent();
        if (!text.includes(step.expected)) {
          throw new Error(`Text mismatch: expected "${step.expected}" in "${text.substring(0, 100)}"`);
        }
        break;
      }

      case 'assertCount': {
        const elements = await page.$$(step.selector);
        const count = elements.length;
        const { min, max, exact } = step;
        if (exact !== undefined && count !== exact) {
          throw new Error(`Count mismatch: expected exactly ${exact}, got ${count}`);
        }
        if (min !== undefined && count < min) {
          throw new Error(`Count mismatch: expected at least ${min}, got ${count}`);
        }
        if (max !== undefined && count > max) {
          throw new Error(`Count mismatch: expected at most ${max}, got ${count}`);
        }
        break;
      }

      case 'screenshot': {
        const name = step.name || `step-${index + 1}`;
        const path = resolve(screenshotDir, `${name}.png`);
        await page.screenshot({ path, fullPage: step.fullPage || false });
        return {
          step: index + 1,
          action,
          status: 'passed',
          duration: Date.now() - startTime,
          screenshot: path,
        };
      }

      case 'wait': {
        await page.waitForTimeout(step.ms || 1000);
        break;
      }

      case 'evaluate': {
        const result = await page.evaluate(step.script);
        return {
          step: index + 1,
          action,
          status: 'passed',
          duration: Date.now() - startTime,
          result,
        };
      }

      case 'selectOption': {
        await page.selectOption(step.selector, step.value, { timeout });
        break;
      }

      case 'check': {
        await page.check(step.selector, { timeout });
        break;
      }

      case 'uncheck': {
        await page.uncheck(step.selector, { timeout });
        break;
      }

      case 'hover': {
        await page.hover(step.selector, { timeout });
        break;
      }

      case 'press': {
        await page.press(step.selector || 'body', step.key, { timeout });
        break;
      }

      case 'type': {
        const typeValue = resolveEnvVars(step.value);
        await page.click(step.selector, { timeout });
        await page.type(step.selector, typeValue, { delay: step.delay || 20 });
        break;
      }

      default:
        throw new Error(`Unknown action: ${action}`);
    }

    return {
      step: index + 1,
      action,
      status: 'passed',
      duration: Date.now() - startTime,
      detail: step.selector || step.url || '',
    };
  } catch (err) {
    // Capture failure screenshot
    const failScreenshot = resolve(screenshotDir, `failure-step-${index + 1}.png`);
    try {
      await page.screenshot({ path: failScreenshot, fullPage: true });
    } catch (_) {
      // Screenshot capture failed, continue
    }

    return {
      step: index + 1,
      action,
      status: 'failed',
      duration: Date.now() - startTime,
      error: err.message,
      screenshot: failScreenshot,
      detail: step.selector || step.url || '',
    };
  }
}

// Main execution
async function runTest() {
  const testStart = Date.now();
  let browser;

  try {
    browser = await chromium.connectOverCDP(cdpUrl, { timeout: 10000 });
  } catch (err) {
    const result = {
      status: 'error',
      error: `Cannot connect to Chrome at ${cdpUrl}: ${err.message}`,
      hint: 'Make sure Chrome is running with: chrome-debug <profile> <port>',
    };
    console.log(JSON.stringify(result, null, 2));
    process.exit(1);
  }

  // Use the first context (default profile)
  const context = browser.contexts()[0];

  // Either reuse existing page or create a new one
  let page;
  let createdNewPage = false;

  if (reuseExistingPage && context.pages().length > 0) {
    // Use the first existing page (reuses auth state)
    page = context.pages()[0];
  } else {
    // Create a new page
    page = await context.newPage();
    createdNewPage = true;
  }

  // Set viewport to stay under Claude API's 2000px image limit
  await page.setViewportSize({ width: 1280, height: 800 });

  const results = [];
  let allPassed = true;

  for (let i = 0; i < steps.length; i++) {
    const stepResult = await executeStep(page, steps[i], i);
    results.push(stepResult);

    if (stepResult.status === 'failed') {
      allPassed = false;
      break; // Stop on first failure
    }
  }

  const totalDuration = Date.now() - testStart;

  // Close the page only if we created a new one (not the browser)
  if (createdNewPage) {
    await page.close().catch(() => {});
  }

  const output = {
    status: allPassed ? 'passed' : 'failed',
    cdpUrl,
    baseUrl,
    totalSteps: steps.length,
    executedSteps: results.length,
    passedSteps: results.filter(r => r.status === 'passed').length,
    failedSteps: results.filter(r => r.status === 'failed').length,
    duration: totalDuration,
    screenshotDir,
    steps: results,
  };

  console.log(JSON.stringify(output, null, 2));
  process.exit(allPassed ? 0 : 1);
}

runTest();
