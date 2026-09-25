#!/usr/bin/env node
'use strict';

const { execFileSync } = require('child_process');
const path = require('path');

const installSh = path.join(__dirname, '..', 'install.sh');
const args = process.argv.slice(2);

try {
  execFileSync('bash', [installSh, ...args], { stdio: 'inherit' });
} catch (err) {
  process.exit(err.status ?? 1);
}
