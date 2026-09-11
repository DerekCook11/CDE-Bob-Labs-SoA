#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$project_dir/vulnerable-app"
target_dir="$project_dir/secure-app"

if [[ -e "$target_dir" ]]; then
  echo "secure-app already exists; no files were changed."
  echo "Use ./scripts/reset-secure-app.sh to preserve it as a backup and start again."
  exit 1
fi

cp -a "$source_dir" "$target_dir"
find "$target_dir" -name 'tasks.db' -delete
echo "Created secure-app. Ask Bob to modify only this copy."

