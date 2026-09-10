# Security Analysis & Code Fixes Lab

This hands-on lab demonstrates how IBM Bob can analyze an existing application,
identify security vulnerabilities, create a remediation plan, implement secure
coding changes, and verify that the findings have been resolved.

The lab includes a working task-management application with a Flask backend,
responsive HTML/JavaScript frontend, and local SQLite database. It is designed
to run on Red Hat Enterprise Linux without PostgreSQL, Docker, Node.js, or
cloud-service dependencies.

> **Security warning:** This project intentionally contains vulnerable code and
> fake hardcoded credentials for educational purposes. Run it only in an
> isolated lab environment. Do not expose it to the internet or deploy it to
> production.

## Download

Download the complete project package:

[Code-Security-Analysis-Lab.zip](./Code-Security-Analysis-Lab.zip)

After downloading or cloning this repository, extract the ZIP file:

```bash
unzip Code-Security-Analysis-Lab.zip
cd Code-Security-Analysis-Lab
```

## Learning objectives

Participants will learn how to:

- Explore an unfamiliar frontend and backend codebase with Bob.
- Use Bob Findings to identify security and code-quality problems.
- Recognize hardcoded secrets, SQL injection, XSS, missing validation,
  sensitive error disclosure, and insecure runtime configuration.
- Create a prioritized remediation plan before modifying code.
- Use Bob Agent Mode to implement security fixes.
- Preserve the original vulnerable code for comparison.
- Validate that security improvements do not break application functionality.
- Produce a before-and-after security report with supporting evidence.

## Application architecture

```text
Browser
   │
   │ HTTP/JSON
   ▼
Flask REST API
   │
   │ SQL
   ▼
SQLite database
```

The application provides:

- Create, list, update, delete, and search operations.
- A responsive task-management interface.
- A Flask REST API running on port `5000`.
- A static frontend running on port `8080`.
- Automatic SQLite database creation and sample data.

## Before-and-after design

The project preserves two application copies:

| Directory | Purpose |
|---|---|
| `vulnerable-app/` | Untouched original application used for the initial scan |
| `secure-app/` | Working copy that Bob analyzes and fixes |

Bob must modify only `secure-app/`. The original `vulnerable-app/` remains
available for file comparison, demonstrations, and repeatable verification.

## Intended security findings

| Finding | Vulnerable area | Expected remediation |
|---|---|---|
| Hardcoded credentials | `backend/config.py` | Environment variables and safe secret handling |
| SQL injection | Search endpoint | Parameterized database query |
| Stored XSS | Frontend task rendering | Safe DOM construction and `textContent` |
| Missing input validation | Create and update endpoints | Type, presence, and length validation |
| Sensitive error disclosure | Global error handler | Server-side logging and generic client errors |
| Insecure runtime settings | Debug mode and wildcard CORS | Secure defaults and restricted origins |
| Secret exposure | Administrative endpoints | Remove sensitive output and require authorization |

All included credentials and keys are fake training values.

## Requirements

- Red Hat Enterprise Linux 9 or another Linux system
- Python 3.9 or later
- Python `pip` and virtual-environment support
- IBM Bob with access to the extracted project
- Two terminal sessions

If Python tooling is not installed, an administrator runs this command once:

```bash
sudo dnf install -y python3 python3-pip
```

All application commands should run as a normal user. Do not run the Flask
application as root.

## Start the vulnerable application

Make the helper scripts executable:

```bash
chmod +x scripts/*.sh
```

In the first terminal, start the Flask backend:

```bash
./scripts/start-backend.sh vulnerable-app
```

The script creates a Python virtual environment, installs the required packages,
creates the SQLite database, loads sample tasks, and starts the API.

In the second terminal, start the frontend:

```bash
./scripts/start-frontend.sh vulnerable-app
```

Open the following address in a browser that can reach the VM:

```text
http://VM-IP:8080
```

The frontend automatically connects to the same VM on port `5000`.

For private access through an SSH tunnel, connect from your workstation with:

```bash
ssh -L 5000:localhost:5000 -L 8080:localhost:8080 itzuser@VM-IP
```

Then open:

```text
http://localhost:8080
```

## Establish the baseline

Activate the virtual environment:

```bash
source .venv/bin/activate
```

Confirm that normal application functions work:

```bash
LAB_TARGET=vulnerable-app python3 -m unittest tests.test_api
```

The functional tests should pass.

Run the security regression tests:

```bash
LAB_TARGET=vulnerable-app python3 -m unittest tests.test_security_regression
```

These tests are intentionally expected to fail before remediation.

Run the static security verification:

```bash
python3 security_verification.py vulnerable-app
```

The original version should report:

```text
Security verification: 0/6 checks passed
```

## Use IBM Bob

Prepared prompts are included in:

```text
prompts/bob-prompts.md
```

Run them in the following order:

1. **Ask Mode:** Understand the application structure and data flow.
2. **Plan Mode:** Identify and prioritize the security findings.
3. **Agent Mode:** Fix the findings only in `secure-app/`.
4. **Verification:** Rescan, test, compare, and document the outcome.

Bob will create these reports during the exercise:

```text
reports/before-security-report.md
reports/remediation-summary.md
reports/after-security-report.md
```

## Verify the secure version

After Bob completes the fixes, run the functional tests against the updated
application:

```bash
LAB_TARGET=secure-app python3 -m unittest tests.test_api
```

Run the security regression tests and static checks:

```bash
LAB_TARGET=secure-app python3 -m unittest tests.test_security_regression
python3 security_verification.py secure-app
```

The expected final result is:

```text
Security verification: 6/6 checks passed
```

Display the differences between the original and secured code:

```bash
./scripts/compare-versions.sh
```

## Run the secured application

Copy the secure environment template and replace its placeholders with lab-only
values:

```bash
cp secure-app/backend/.env.example secure-app/backend/.env
vi secure-app/backend/.env
```

Stop the original application and start the secured version:

```bash
./scripts/start-backend.sh secure-app
./scripts/start-frontend.sh secure-app
```

Run the backend and frontend commands in separate terminals.

## Reset the lab

To repeat the exercise:

```bash
./scripts/reset-secure-app.sh
```

The reset script preserves the previous secured application in a timestamped
backup before creating a fresh working copy from `vulnerable-app/`.

## Project structure

```text
Code-Security-Analysis-Lab/
├── vulnerable-app/
│   ├── backend/
│   └── frontend/
├── secure-app/
│   ├── backend/
│   └── frontend/
├── prompts/
│   └── bob-prompts.md
├── reports/
├── scripts/
│   ├── compare-versions.sh
│   ├── reset-secure-app.sh
│   ├── start-backend.sh
│   └── start-frontend.sh
├── tests/
│   ├── test_api.py
│   └── test_security_regression.py
├── security_verification.py
└── README.md
```

## Success criteria

The lab is complete when:

- The vulnerable application starts without an external database.
- Normal functional tests pass before and after remediation.
- Bob identifies the intended vulnerabilities with evidence and severity.
- Bob modifies only `secure-app/`.
- Security checks fail against the original version and pass against the fixed
  version.
- The final report maps each finding to its code change and verification
  evidence.

