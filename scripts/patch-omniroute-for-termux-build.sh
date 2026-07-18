#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${1:-omniroute}"
cd "$APP_DIR"

# 1) Keep a backup and replace @swc/core native binding loader with a minimal stub.
# This mirrors the Android/Termux runtime workaround: build-time plugins may require
# @swc/core even though Android has no native binding. The GitHub ARM64 runner has a
# Linux binding, but the artifact is meant for Android Termux, so avoid baking in a
# platform-specific assumption from this loader.
if [ -f node_modules/@swc/core/binding.js ] && [ ! -f node_modules/@swc/core/binding.js.orig ]; then
  cp node_modules/@swc/core/binding.js node_modules/@swc/core/binding.js.orig
fi
cat > node_modules/@swc/core/binding.js <<'JS'
'use strict';

function unavailable(name) {
  return function () {
    throw new Error('@swc/core native binding is intentionally stubbed for portable Termux artifact: ' + name);
  };
}

module.exports = new Proxy({
  getTargetTriple() {
    return 'aarch64-linux-android';
  },
}, {
  get(target, prop) {
    if (prop in target) return target[prop];
    if (prop === '__esModule') return false;
    return unavailable(String(prop));
  },
});
JS

# 2) Provide a compile-time stub for @huggingface/transformers. OmniRoute imports it
# in optional local-transformers code paths, but it may be absent after install on
# constrained/mobile platforms. The service should not use local transformer features
# on the phone.
mkdir -p node_modules/@huggingface/transformers
cat > node_modules/@huggingface/transformers/package.json <<'JSON'
{
  "name": "@huggingface/transformers",
  "version": "0.0.0-termux-stub",
  "type": "module",
  "main": "index.js",
  "module": "index.js"
}
JSON
cat > node_modules/@huggingface/transformers/index.js <<'JS'
export async function pipeline() {
  throw new Error('@huggingface/transformers is stubbed in the Termux production artifact');
}
export default { pipeline };
JS

# 3) Make the Next dev origin list optionally accept LAN origins when the artifact is
# later used in dev fallback. Production does not rely on this, but keeping it harmless.
if [ -f next.config.mjs ] && ! grep -q 'OMNIROUTE_DEV_ORIGINS' next.config.mjs; then
  python3 - <<'PY'
from pathlib import Path
p = Path('next.config.mjs')
s = p.read_text()
needle = 'const nextConfig = {'
if needle in s:
    s = s.replace(needle, "const extraAllowedDevOrigins = (process.env.OMNIROUTE_DEV_ORIGINS || '').split(',').filter(Boolean);\n\nconst nextConfig = {", 1)
    marker = 'const nextConfig = {\n'
    s = s.replace(marker, marker + "  allowedDevOrigins: ['localhost', '127.0.0.1', ...extraAllowedDevOrigins],\n", 1)
p.write_text(s)
PY
fi
