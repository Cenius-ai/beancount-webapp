#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "=== BeanCount: install & setup ==="

# 1. Create .env if not present
if [ ! -f .env ]; then
  cp .env.example .env
  # generate per-install secrets (auto-added by cenius)
  _cenius_gen() { openssl rand -hex 32 2>/dev/null || (head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n'); }
  for _k in SESSION_SECRET; do
    if grep -qiE "^${_k}=(<.*>|change[-_]?me.*|[[:space:]]*)$" .env 2>/dev/null; then
      sed -i "s|^${_k}=.*|${_k}=$(_cenius_gen)|" .env; fi
  done
  echo "[install] Created .env from .env.example"
fi

# 2. Install dependencies & build
echo "[install] Building with nimble…"
nimble build -y

# 3. Seed happens automatically on first run (idempotent)

echo ""
echo "=== Setup complete ==="
echo "Start the server: ./beancount"
echo "Then open: http://localhost:5000"
echo "Demo login: cenius@cenius.ai / cenius"
