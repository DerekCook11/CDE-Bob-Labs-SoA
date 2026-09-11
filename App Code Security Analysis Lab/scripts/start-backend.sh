#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="${1:-vulnerable-app}"

if [[ "$target" != "vulnerable-app" && "$target" != "secure-app" ]]; then
  echo "Usage: $0 [vulnerable-app|secure-app]"
  exit 2
fi

if [[ ! -d "$project_dir/.venv" ]]; then
  python3 -m venv "$project_dir/.venv"
fi

env_file="$project_dir/$target/backend/.env"
if [[ -f "$env_file" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
fi

"$project_dir/.venv/bin/python" -m pip install -r "$project_dir/$target/backend/requirements.txt"
cd "$project_dir/$target/backend"
exec "$project_dir/.venv/bin/python" app.py
