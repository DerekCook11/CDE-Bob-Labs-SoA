# Security Analysis & Code Fixes Lab

Analyze a vulnerable todo application, identify security issues with Bob, plan fixes, and implement secure coding improvements.

**Duration:** 30 minutes

**Difficulty:** Intermediate

## Overview

In this lab, you'll use Bob to analyze existing code, identify security vulnerabilities, and implement fixes. You'll learn to recognize common security issues like SQL injection, XSS, and hardcoded secrets, then use Bob's different modes to fix them.

> **🔍 Bob Differentiator: Bob Findings**
> This lab showcases Bob Findings, Bob's automated security and code quality analysis engine. Unlike simple linters, Bob Findings provides continuous, proactive analysis with specific remediation recommendations, severity ratings, and code examples. It's like having a security expert reviewing your code in real-time!

## What You'll Analyze

A vulnerable todo application with intentional security flaws:

- **SQL Injection** vulnerabilities in database queries
- **Cross-Site Scripting (XSS)** in frontend code
- **Hardcoded secrets** and credentials
- **Missing input validation**
- **Insecure error handling**

## Learning Objectives

By the end of this lab, you will:

- ✅ Use Ask mode to understand existing codebases
- ✅ Use Architect mode to identify bugs and plan fixes
- ✅ Recognize SQL injection vulnerabilities
- ✅ Identify XSS attack vectors
- ✅ Find hardcoded secrets and credentials
- ✅ Implement security fixes using Agent mode
- ✅ Apply secure coding best practices

## Lab Structure

```text
Security Analysis & Code Fixes Lab Timeline (30 minutes)
├── Step 1: Code Exploration (10 min)
├── Step 2: Bug Identification (10 min)
└── Step 3: Implementing Fixes (10 min)
```

---

## Step 1: Code Exploration with Ask Mode (10 minutes)

### Understanding the Vulnerable Codebase

The `vulnerable-app/` directory contains a todo application with intentional security issues. Let's use Bob's Ask mode to understand the code structure.

### 1.1: Switch to Ask Mode

Open Bob and switch to **Ask Mode** (❓).

### 1.2: Explore the Backend

**Prompt for Bob:**

```
Please analyze the code in vulnerable-app/backend/ and explain:
1. What is the overall structure of the application?
2. How are database queries constructed?
3. How is user input handled?
4. What security measures are in place?
save results as interactive html file
```

**What to Look For:**

Bob should identify:

- Flask application with REST API endpoints
- Direct string concatenation in SQL queries ⚠️
- Hardcoded database credentials ⚠️
- Missing input validation ⚠️

### 1.3: Explore the Frontend

**Prompt for Bob:**

```
Analyze the frontend code in vulnerable-app/frontend/ and explain:
1. How is user input displayed in the UI?
2. Are there any DOM manipulation methods that could be risky?
3. How is data from the API rendered?
save results as interactive html file
```

**What to Look For:**

Bob should identify:

- Use of `innerHTML` for rendering user content ⚠️
- No input sanitization ⚠️
- Direct insertion of user data into DOM ⚠️

### 1.4: Ask About Specific Functions

**Prompt for Bob:**

```
Explain the search_todos() function in app.py. 
What does it do and are there any security concerns?
save results as interactive html file
```

**Expected Response:**

Bob should explain that the function uses string formatting to build SQL queries, which is vulnerable to SQL injection attacks.

**💡 Key Learning**: Ask mode is perfect for understanding unfamiliar code and getting explanations of how things work.

---

## Step 2: Bug Identification with Plan Mode (10 minutes)

Now let's use Architect mode to systematically identify all the issues.

### 2.1: Switch to Plan Mode

Change from Ask to **Plan Mode** (🎯).

### 2.2: Request Security Analysis

> **💡 Using Bob Findings**
> Bob Findings can automatically scan your code for security vulnerabilities, code quality issues, and compliance violations. The analysis you're about to request demonstrates Bob's [Security Vulnerability Detection](../bob-differentiators.md#security-vulnerability-detection) capabilities, which go beyond basic static analysis to provide context-aware recommendations.

**Prompt for Bob:**

```
Analyze the codebase in vulnerable-app/ for security vulnerabilities.
Create a comprehensive report including:
1. List of all security issues found
2. Severity rating for each issue (Critical/High/Medium/Low)
3. Potential impact of each vulnerability
4. Recommended fix for each issue
5. Priority order for fixes
save results as interactive html file
```

**Expected Output:**

Bob should provide a structured analysis like:

```
SECURITY ANALYSIS REPORT
========================

CRITICAL ISSUES:
1. Hardcoded Database Credentials (config.py)
   - Impact: Full database access if code is exposed
   - Fix: Use environment variables
   - Priority: 1

2. SQL Injection (app.py, search_todos function)
   - Impact: Unauthorized data access, data manipulation
   - Fix: Use parameterized queries
   - Priority: 1

HIGH ISSUES:
3. Cross-Site Scripting (app.js, displayTodo function)
   - Impact: Script injection, session hijacking
   - Fix: Use textContent instead of innerHTML
   - Priority: 2

MEDIUM ISSUES:
4. Missing Input Validation
   - Impact: Invalid data in database
   - Fix: Add validation middleware
   - Priority: 3
```

### 2.3: Create Fix Plan

**Prompt for Bob:**

```
Based on the security analysis, create a detailed plan for fixing these issues.
Include:
1. Order of fixes (most critical first)
2. Files that need to be modified
3. Specific code changes required
4. Testing strategy
save results as interactive html file
```

**Bob's Response:**

Bob will create a detailed TODO list with all the fixes needed. This demonstrates Bob's ability to break down complex problems into actionable steps.

**⚠️ Important**: Review the TODO list Bob creates, but **do not implement the fixes yet**. We'll examine each vulnerability type in detail in the next step before making any changes.

**💡 Key Learning**: Plan mode excels at analysis, planning, and creating structured approaches to problems. The TODO list serves as your roadmap for the implementation phase.

---

## Step 3: Implementing Fixes with Agent Mode (10 minutes)

Now let's fix all the vulnerabilities using Bob's Agent mode.

### 3.1: Switch to Agent Mode

Change to **Agent Mode** (💻).

### 3.2: Fix SQL Injection

**Prompt for Bob:**

```
Fix the SQL injection vulnerability in vulnerable-app/backend/app.py.
Replace the string formatting with parameterized queries using SQLAlchemy.
save results as interactive html file
```

Bob should modify the `search_todos()` function to use safe queries.

### 3.3: Fix XSS Vulnerability

**Prompt for Bob:**

```
Fix the XSS vulnerability in vulnerable-app/frontend/app.js.
Replace innerHTML usage with safe DOM manipulation using textContent.
Update all functions that display user-generated content.
Save results as interactive html file
```

### 3.4: Fix Hardcoded Secrets

**Prompt for Bob:**

```
Fix the hardcoded secrets in vulnerable-app/backend/config.py.
1. Move secrets to environment variables
2. Create a .env.example file with placeholder values
3. Add python-dotenv to requirements.txt
4. Update the code to load from environment
Save results as interactive html file
```

### 3.5: Add Input Validation

**Prompt for Bob:**

```
Add input validation to the todo creation endpoint.
Validate:
- Title is required and not empty
- Title length is between 1 and 200 characters
- Description length is less than 1000 characters
Return appropriate error messages for invalid input
Save results as interactive html file.
```

### 3.6: Verify Fixes

**Important**: Bob has made the fixes directly to the files in `vulnerable-app/` (not in a separate solution folder). The vulnerable code has been replaced with secure code.

Run the application and test the fixes:

```bash
# Start backend (from the vulnerable-app directory where fixes were applied)
cd vulnerable-app/backend
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
python app.py # may conflict with AirPlay on the Mac, in which case run the following instead:
FLASK_RUN_PORT=8080 flask run

# Open frontend (from the vulnerable-app directory)
cd ../frontend
# Open index.html in browser
```

**Test Security:**

1. Try SQL injection - should fail safely (no data leaked)
2. Try XSS payload - should display as plain text (not execute)
3. Check no secrets in code (verify config.py uses environment variables)
4. Test input validation (try empty title, too long title, etc.)

## Congratulations! 🎉

You've successfully completed Security Analysis & Code Fixes Lab! You've learned to:

- ✅ Use Ask mode to understand existing code
- ✅ Use Architect mode for security analysis
- ✅ Identify SQL injection vulnerabilities
- ✅ Recognize XSS attack vectors
- ✅ Find and fix hardcoded secrets
- ✅ Implement secure coding practices
- ✅ Use Agent mode to fix security issues

> **🎯 Bob Findings in Action**
> In this lab, you experienced Bob's [automated security analysis](../bob-differentiators.md#security-vulnerability-detection) capabilities. Bob Findings continuously monitors your code for vulnerabilities and provides actionable remediation guidance. This proactive approach helps you catch security issues before they reach production, reducing risk and technical debt.

## Security Best Practices Learned

### 1. SQL Injection Prevention

- ✅ Always use parameterized queries
- ✅ Never concatenate user input into SQL
- ✅ Use ORM features (like SQLAlchemy)
- ✅ Validate and sanitize input

### 2. XSS Prevention

- ✅ Use `textContent` instead of `innerHTML`
- ✅ Sanitize user input before display
- ✅ Use Content Security Policy headers
- ✅ Encode output properly

### 3. Secrets Management

- ✅ Never hardcode credentials
- ✅ Use environment variables
- ✅ Use secret management services
- ✅ Rotate secrets regularly
- ✅ Never commit secrets to version control

### 4. Input Validation

- ✅ Validate all user input
- ✅ Use whitelist validation
- ✅ Set appropriate length limits
- ✅ Return clear error messages
