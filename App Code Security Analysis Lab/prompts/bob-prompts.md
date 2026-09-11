# IBM Bob prompts

Use these prompts in order. Keep `vulnerable-app/` unchanged. Bob should make
all code changes only in `secure-app/`.

## 1. Ask Mode — understand the application

```text
Analyze vulnerable-app/backend and vulnerable-app/frontend.

Explain:
1. The application architecture and request flow.
2. How the frontend calls the Flask API.
3. How the API reads and writes SQLite data.
4. Every place where user-controlled data enters the application.
5. The purpose of each file.

Do not modify any files.
```

## 2. Plan Mode — security analysis

```text
Perform a security review of vulnerable-app/. Use Bob Findings where available.

For every finding include:
- Severity: Critical, High, Medium, or Low
- CWE or OWASP category where applicable
- Affected file and function
- Evidence from the code
- Exploitation scenario and business impact
- Recommended remediation
- Regression test needed

Pay particular attention to secret management, SQL construction, DOM rendering,
input validation, error handling, administrative endpoints, CORS, and debug mode.
Create reports/before-security-report.md. Do not modify the application code.
```

## 3. Agent Mode — implement the fixes

```text
Remediate the approved security findings only in secure-app/.
Never modify vulnerable-app/.

Requirements:
1. Read secrets from environment variables and fail safely when required values
   are absent. Update .env.example with non-secret placeholders.
2. Replace dynamic SQL construction with parameterized queries.
3. Render user content using safe DOM APIs such as textContent; do not insert
   user-controlled values through innerHTML.
4. Validate JSON bodies, required fields, data types, boolean values, and
   reasonable title/description lengths on create and update. Use a shared
   validate_task_payload function and an explicit MAX_TITLE_LENGTH constant so
   validation is consistent and verifiable.
5. Return generic client-safe errors while logging useful details server-side.
6. Remove or protect endpoints that expose secrets. Never return secret values.
7. Disable debug mode by default and restrict CORS to configured origins.
8. Preserve create, list, update, delete, search, health-check, and responsive UI
   behavior.
9. Add or update security regression tests without weakening the verification
   criteria.

Run the functional and security verification commands. Summarize each changed
file and create reports/remediation-summary.md.
```

## 4. Verification — rescan and compare

```text
Rescan secure-app/ and compare it with vulnerable-app/.

Confirm whether each original finding is fixed, partially fixed, or still open.
Run:

LAB_TARGET=secure-app python3 -m unittest tests.test_api
LAB_TARGET=secure-app python3 -m unittest tests.test_security_regression
python3 security_verification.py secure-app
./scripts/compare-versions.sh

Do not claim a finding is fixed unless the updated code and tests support the
claim. Create reports/after-security-report.md with a before-and-after table,
test results, remaining risks, and recommended next steps.
```
