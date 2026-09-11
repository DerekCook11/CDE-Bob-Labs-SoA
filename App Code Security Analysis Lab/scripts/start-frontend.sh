#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="${1:-vulnerable-app}"

if [[ "$target" != "vulnerable-app" && "$target" != "secure-app" ]]; then
  echo "Usage: $0 [vulnerable-app|secure-app]"
  exit 2
fi

cd "$project_dir/$target/frontend"
exec python3 -m http.server 8080 --bind 0.0.0.0

