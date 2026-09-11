#!/usr/bin/env bash
set -u

# Security Analysis & Code Fixes Lab
# Prerequisite validation and end-to-end application smoke test.
#
# Usage:
#   ./lab-preflight-and-smoke-test.sh
#   ./lab-preflight-and-smoke-test.sh --install
#
# Optional overrides:
#   API_BASE=http://127.0.0.1:5000/api
#   FRONTEND_URL=http://127.0.0.1:8080
#   LAB_PROJECT_DIR=/path/to/Code-Security-Analysis-Lab

API_BASE="${API_BASE:-http://127.0.0.1:5000/api}"
FRONTEND_URL="${FRONTEND_URL:-http://127.0.0.1:8080}"
INSTALL_MISSING=false
[[ "${1:-}" == "--install" ]] && INSTALL_MISSING=true

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="${LAB_PROJECT_DIR:-$script_dir}"

pass_count=0
fail_count=0
warn_count=0
smoke_task_id=""
check_dir=""

if [[ -t 1 ]]; then
  green=$'\033[32m'
  red=$'\033[31m'
  yellow=$'\033[33m'
  cyan=$'\033[36m'
  reset=$'\033[0m'
else
  green="" red="" yellow="" cyan="" reset=""
fi

heading() {
  echo
  echo "${cyan}== $* ==${reset}"
}

pass() {
  pass_count=$((pass_count + 1))
  echo "${green}PASS${reset}: $*"
}

fail() {
  fail_count=$((fail_count + 1))
  echo "${red}FAIL${reset}: $*"
}

warn() {
  warn_count=$((warn_count + 1))
  echo "${yellow}WARN${reset}: $*"
}

cleanup() {
  if [[ -n "$smoke_task_id" ]] && command -v curl >/dev/null 2>&1; then
    curl -sS --connect-timeout 2 --max-time 5 \
      -X DELETE "$API_BASE/tasks/$smoke_task_id" >/dev/null 2>&1 || true
  fi

  if [[ -n "$check_dir" && -d "$check_dir" && "$check_dir" == /tmp/* ]]; then
    rm -rf "$check_dir"
  fi
}
trap cleanup EXIT INT TERM

echo "Security Analysis & Code Fixes Lab"
echo "Preflight and application smoke test"
echo "Project:  $project_dir"
echo "API:      $API_BASE"
echo "Frontend: $FRONTEND_URL"

heading "1. Operating system commands"

declare -a missing_packages=()

check_command() {
  local command_name="$1"
  local package_name="$2"
  if command -v "$command_name" >/dev/null 2>&1; then
    pass "$command_name is installed ($(command -v "$command_name"))"
  else
    fail "$command_name is not installed"
    missing_packages+=("$package_name")
  fi
}

check_command python3 python3
check_command curl curl
check_command unzip unzip
check_command git git

if ((${#missing_packages[@]} > 0)); then
  # Remove duplicate package names without requiring external tools.
  declare -a unique_packages=()
  for package in "${missing_packages[@]}"; do
    already_added=false
    for existing in "${unique_packages[@]:-}"; do
      [[ "$existing" == "$package" ]] && already_added=true
    done
    [[ "$already_added" == false ]] && unique_packages+=("$package")
  done

  echo
  echo "Missing packages can be installed with:"
  echo "  sudo dnf install -y ${unique_packages[*]} python3-pip"

  if [[ "$INSTALL_MISSING" == true ]]; then
    echo
    echo "Installing missing packages with sudo..."
    if sudo dnf install -y "${unique_packages[@]}" python3-pip; then
      pass "Missing operating system packages were installed"
    else
      fail "Package installation failed; ask the VM administrator to run the command above"
    fi
  else
    echo "Rerun with --install to execute that command automatically."
  fi
fi

if ! command -v python3 >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
  echo
  echo "Cannot continue until Python 3 and curl are installed."
  exit 1
fi

heading "2. Python runtime"

python_version="$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))' 2>/dev/null || true)"
if python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)' 2>/dev/null; then
  pass "Python $python_version meets the 3.9+ requirement"
else
  fail "Python $python_version is older than 3.9"
fi

if python3 -m pip --version >/dev/null 2>&1; then
  pass "Python pip is available"
else
  fail "Python pip is unavailable"
  echo "  Install it with: sudo dnf install -y python3-pip"
fi

if python3 -c 'import sqlite3' >/dev/null 2>&1; then
  sqlite_version="$(python3 -c 'import sqlite3; print(sqlite3.sqlite_version)')"
  pass "Python SQLite support is available ($sqlite_version)"
else
  fail "Python SQLite support is unavailable"
  echo "  Repair Python with: sudo dnf reinstall -y python3 python3-libs"
fi

check_dir="$(mktemp -d /tmp/bob-lab-check.XXXXXX)"
if python3 -m venv "$check_dir/venv" >/dev/null 2>&1 \
  && "$check_dir/venv/bin/python" -m pip --version >/dev/null 2>&1; then
  pass "Python virtual environments can be created with pip"
else
  fail "Python virtual-environment creation failed"
  echo "  Install or repair it with: sudo dnf install -y python3 python3-pip"
fi

heading "3. Lab project files"

required_paths=(
  "vulnerable-app/backend/app.py"
  "vulnerable-app/backend/requirements.txt"
  "vulnerable-app/frontend/index.html"
  "secure-app/backend/app.py"
  "secure-app/frontend/index.html"
  "scripts/start-backend.sh"
  "scripts/start-frontend.sh"
  "security_verification.py"
)

project_files_ok=true
for relative_path in "${required_paths[@]}"; do
  if [[ -f "$project_dir/$relative_path" ]]; then
    pass "$relative_path found"
  else
    fail "$relative_path is missing"
    project_files_ok=false
  fi
done

if [[ ! -w "$project_dir" ]]; then
  fail "The current user cannot write to $project_dir"
else
  pass "The current user can write to the lab directory"
fi

if [[ "$project_files_ok" == false ]]; then
  echo
  echo "Run this script from the extracted Code-Security-Analysis-Lab directory,"
  echo "or set LAB_PROJECT_DIR to that directory."
  exit 1
fi

if [[ -x "$project_dir/.venv/bin/python" ]]; then
  if "$project_dir/.venv/bin/python" -c 'import flask, flask_cors' >/dev/null 2>&1; then
    pass "Flask and Flask-CORS are installed in .venv"
  else
    fail "The existing .venv is missing Flask dependencies"
    echo "  Install them with:"
    echo "  $project_dir/.venv/bin/python -m pip install -r $project_dir/vulnerable-app/backend/requirements.txt"
  fi
else
  warn ".venv does not exist yet; start-backend.sh will create it automatically"
fi

heading "4. Application reachability"

health_file="$check_dir/health.json"
health_code="$(curl -sS --connect-timeout 3 --max-time 10 \
  -o "$health_file" -w '%{http_code}' "$API_BASE/health" 2>/dev/null || true)"

if [[ "$health_code" != "200" ]]; then
  fail "Backend health endpoint did not return HTTP 200 (received ${health_code:-no response})"
  echo
  echo "Start the backend in terminal 1:"
  echo "  cd \"$project_dir\""
  echo "  ./scripts/start-backend.sh vulnerable-app"
  echo
  echo "Then rerun this smoke-test script in another terminal."
  exit 1
fi

if python3 -c 'import json,sys; data=json.load(open(sys.argv[1])); raise SystemExit(0 if data.get("status") == "healthy" else 1)' "$health_file"; then
  pass "Backend health endpoint reports healthy"
else
  fail "Backend returned HTTP 200 but did not report healthy"
fi

frontend_code="$(curl -sS --connect-timeout 3 --max-time 10 \
  -o /dev/null -w '%{http_code}' "$FRONTEND_URL" 2>/dev/null || true)"
if [[ "$frontend_code" == "200" ]]; then
  pass "Frontend is reachable at $FRONTEND_URL"
else
  fail "Frontend did not return HTTP 200 (received ${frontend_code:-no response})"
  echo "  Start it in terminal 2 with: ./scripts/start-frontend.sh vulnerable-app"
fi

heading "5. API functional smoke test"

tasks_file="$check_dir/tasks.json"
tasks_code="$(curl -sS --connect-timeout 3 --max-time 10 \
  -o "$tasks_file" -w '%{http_code}' "$API_BASE/tasks" 2>/dev/null || true)"
if [[ "$tasks_code" == "200" ]] \
  && python3 -c 'import json,sys; raise SystemExit(0 if isinstance(json.load(open(sys.argv[1])), list) else 1)' "$tasks_file"; then
  pass "GET /tasks returned a JSON task list"
else
  fail "GET /tasks failed or did not return a JSON list (HTTP ${tasks_code:-no response})"
  [[ -s "$tasks_file" ]] && sed -n '1,10p' "$tasks_file"
  exit 1
fi

smoke_title="Bob smoke test $(date +%s)"
create_payload="$(printf '{\"title\":\"%s\",\"description\":\"Automated lab verification\"}' "$smoke_title")"
create_file="$check_dir/create.json"
create_code="$(curl -sS --connect-timeout 3 --max-time 10 \
  -o "$create_file" -w '%{http_code}' \
  -H 'Content-Type: application/json' \
  -X POST --data "$create_payload" "$API_BASE/tasks" 2>/dev/null || true)"

if [[ "$create_code" == "201" ]]; then
  smoke_task_id="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("id", ""))' "$create_file" 2>/dev/null || true)"
  if [[ "$smoke_task_id" =~ ^[0-9]+$ ]]; then
    pass "POST /tasks created temporary task ID $smoke_task_id"
  else
    fail "POST /tasks did not return a numeric task ID"
    exit 1
  fi
else
  fail "POST /tasks failed (HTTP ${create_code:-no response})"
  [[ -s "$create_file" ]] && sed -n '1,10p' "$create_file"
  exit 1
fi

update_payload="$(printf '{\"title\":\"%s\",\"description\":\"Automated lab verification\",\"completed\":true}' "$smoke_title")"
update_file="$check_dir/update.json"
update_code="$(curl -sS --connect-timeout 3 --max-time 10 \
  -o "$update_file" -w '%{http_code}' \
  -H 'Content-Type: application/json' \
  -X PUT --data "$update_payload" "$API_BASE/tasks/$smoke_task_id" 2>/dev/null || true)"

if [[ "$update_code" == "200" ]] \
  && python3 -c 'import json,sys; raise SystemExit(0 if json.load(open(sys.argv[1])).get("completed") is True else 1)' "$update_file"; then
  pass "PUT /tasks/$smoke_task_id marked the task complete"
else
  fail "PUT /tasks/$smoke_task_id failed or did not return completed=true (HTTP ${update_code:-no response})"
fi

search_file="$check_dir/search.json"
search_code="$(curl -sS --connect-timeout 3 --max-time 10 \
  -o "$search_file" -w '%{http_code}' \
  --get --data-urlencode "q=$smoke_title" "$API_BASE/tasks/search" 2>/dev/null || true)"

if [[ "$search_code" == "200" ]] \
  && python3 -c 'import json,sys; target=int(sys.argv[2]); data=json.load(open(sys.argv[1])); raise SystemExit(0 if any(item.get("id") == target for item in data) else 1)' "$search_file" "$smoke_task_id"; then
  pass "GET /tasks/search found the temporary task"
else
  fail "GET /tasks/search did not find task ID $smoke_task_id (HTTP ${search_code:-no response})"
fi

delete_file="$check_dir/delete.json"
delete_code="$(curl -sS --connect-timeout 3 --max-time 10 \
  -o "$delete_file" -w '%{http_code}' \
  -X DELETE "$API_BASE/tasks/$smoke_task_id" 2>/dev/null || true)"

if [[ "$delete_code" == "200" ]]; then
  pass "DELETE /tasks/$smoke_task_id removed the temporary task"
  smoke_task_id=""
else
  fail "DELETE /tasks/$smoke_task_id failed (HTTP ${delete_code:-no response})"
fi

heading "6. Result"

echo "Passed:   $pass_count"
echo "Warnings: $warn_count"
echo "Failed:   $fail_count"

if ((fail_count == 0)); then
  echo
  echo "${green}LAB READY: Prerequisites are met and the application is functioning.${reset}"
  exit 0
fi

echo
echo "${red}NOT READY: Resolve the failed checks above and rerun this script.${reset}"
exit 1

