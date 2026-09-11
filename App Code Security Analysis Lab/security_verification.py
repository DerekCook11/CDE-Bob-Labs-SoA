#!/usr/bin/env python3
"""Lightweight static checks for the Bob security remediation exercise."""

import re
import sys
from pathlib import Path


def read(path):
    return path.read_text(encoding="utf-8")


def main():
    target = Path(sys.argv[1] if len(sys.argv) > 1 else "secure-app").resolve()
    backend = target / "backend"
    frontend = target / "frontend"
    required = [backend / "config.py", backend / "app.py", frontend / "app.js"]

    missing = [str(path) for path in required if not path.exists()]
    if missing:
        print("Missing required files:")
        for path in missing:
            print(f"  - {path}")
        return 2

    config_text = read(required[0])
    app_text = read(required[1])
    js_text = read(required[2])

    hardcoded_secret = re.search(
        r"^(SECRET_KEY|ADMIN_PASSWORD|API_KEY)\s*=\s*['\"][^'\"]+['\"]",
        config_text,
        re.MULTILINE,
    )
    exposed_secret = "/api/admin/config" in app_text or '"api_key": config.API_KEY' in app_text
    dynamic_sql = bool(re.search(r"sql\s*=\s*f[\"']", app_text))
    unsafe_dom = ".innerHTML" in js_text
    has_validation = (
        "validate_task_payload" in app_text
        and "MAX_TITLE_LENGTH" in app_text
        and "isinstance" in app_text
    )
    leaks_errors = bool(
        re.search(r"['\"]details['\"]\s*:\s*str\(", app_text)
        or re.search(r"['\"]type['\"]\s*:\s*type\(", app_text)
    )
    insecure_runtime = bool(
        re.search(r"^DEBUG\s*=\s*True", config_text, re.MULTILINE)
        or re.search(r"^CORS_ORIGINS\s*=\s*['\"]\*['\"]", config_text, re.MULTILINE)
    )

    checks = [
        ("No hardcoded or exposed application secrets", not hardcoded_secret and not exposed_secret),
        ("Search query is parameterized", not dynamic_sql),
        ("User content uses safe DOM rendering", not unsafe_dom),
        ("Task input validation is implemented", has_validation),
        ("Internal errors are not returned to clients", not leaks_errors),
        ("Debug and CORS defaults are secure", not insecure_runtime),
    ]

    print(f"Security verification target: {target.name}\n")
    for label, passed in checks:
        print(f"{'PASS' if passed else 'FAIL'}: {label}")

    passed_count = sum(passed for _, passed in checks)
    print(f"\nSecurity verification: {passed_count}/{len(checks)} checks passed")
    return 0 if passed_count == len(checks) else 1


if __name__ == "__main__":
    raise SystemExit(main())

