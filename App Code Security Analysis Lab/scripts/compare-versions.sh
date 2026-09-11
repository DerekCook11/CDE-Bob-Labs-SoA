#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

diff -ru \
  --exclude='tasks.db' \
  --exclude='__pycache__' \
  "$project_dir/vulnerable-app" \
  "$project_dir/secure-app" || true

