#!/usr/bin/env node
// Loader to handle CommonJS duckdb and ESM MCP SDK
import { createRequire } from 'node:module';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';

const require = createRequire(import.meta.url);

// Pre-load modules and make them available globally
globalThis.__duckdb = require('duckdb');
globalThis.__mcp = { McpServer, StdioServerTransport };

// Now load the main module
await import('../target/js/release/build/main/main.js');
