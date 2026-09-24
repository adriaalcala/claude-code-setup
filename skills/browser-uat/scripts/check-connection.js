#!/usr/bin/env node
// check-connection.js — Verify Chrome CDP connection is alive
// Usage: node check-connection.js [port]

import { chromium } from 'playwright';

const port = process.argv[2] || '9222';
const cdpUrl = `http://localhost:${port}`;

async function checkConnection() {
  let browser;
  try {
    browser = await chromium.connectOverCDP(cdpUrl, { timeout: 5000 });
    const contexts = browser.contexts();
    const pages = contexts.flatMap(ctx => ctx.pages());

    const version = await browser.version();

    const result = {
      status: 'connected',
      cdpUrl,
      version,
      contexts: contexts.length,
      tabs: pages.length,
      pages: pages.map(p => ({
        title: p.url(),
      })),
    };

    console.log(JSON.stringify(result, null, 2));
    process.exit(0);
  } catch (err) {
    const result = {
      status: 'error',
      cdpUrl,
      error: err.message,
      hint: `Make sure Chrome is running with: chrome-debug <profile> ${port}`,
    };

    console.log(JSON.stringify(result, null, 2));
    process.exit(1);
  } finally {
    if (browser) {
      // Don't close — we're just checking, not owning the browser
      browser.close().catch(() => {});
    }
  }
}

checkConnection();
