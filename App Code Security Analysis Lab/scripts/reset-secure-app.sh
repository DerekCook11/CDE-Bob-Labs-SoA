#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$project_dir/vulnerable-app"
target_dir="$project_dir/secure-app"
backup_dir="$project_dir/secure-app.backup.$(date +%Y%m%d-%H%M%S)"

if [[ -d "$target_dir" ]]; then
  mv "$target_dir" "$backup_dir"
  echo "Preserved the previous secure-app at: $backup_dir"
fi

cp -a "$source_dir" "$target_dir"
find "$target_dir" -name 'tasks.db' -delete
echo "Reset secure-app from the untouched vulnerable baseline."

