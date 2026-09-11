# Ansible Lab Workshop Plan

## Overview

The goal is to build a self-contained workshop inside the `Ansible Lab` directory that teaches developers how to use IBM Bob's AI-assisted workflow to create, containerize, and deploy a Node.js/Express REST API using Ansible and Podman — all on a RHEL VM.

The student interacts with Bob throughout the lab using natural-language prompts. Bob generates all project files. The student's job is to understand what Bob creates and why. The lab uses the existing `⚡ Ansible Developer` custom mode for Ansible work and switches to general agent mode for application and container tasks.

**Key constraints:**
- No external container registry — build and run entirely on the local RHEL VM
- Ansible work uses roles for modularity — no monolithic playbooks; each role has a single responsibility
- Two thin playbooks act as entry points: `setup.yml` (calls `podman_setup` role) and `deploy.yml` (calls `deploy_app` role)
- The `podman_setup` role installs both Podman and the `containers.podman` Ansible collection, so the deploy role can use proper collection modules
- Parts 1–3 use Bob's default Agent mode; Parts 4–5 switch to `⚡ Ansible Developer` mode
- Lab instructions are clean and professional — no excessive verbosity or emojis
- All generated files live in `Ansible Lab/` alongside the instructions
- Audience: developers with basic Linux/terminal familiarity, new to Ansible and containers

---

## Sub-Tasks

---

### Task 1 — Create the Lab Instruction File Structure

**Status:** `[x] done`

**Intent:**
Establish the final `lab.md` document structure with sections, headings, and prose framing so subsequent tasks slot content into place cleanly. The current `lab.md` has a rough start that needs to be reshaped into a professional multi-section document.

**Expected Outcomes:**
- `Ansible Lab/Lab Instructions/lab.md` contains a complete skeleton: title, overview, prerequisites, and one section per lab phase with placeholder content
- Tone is concise and professional — no emojis, no padding
- The `.bobignore` already excludes `Lab Instructions` from Bob's context (confirmed), so the file is safe to write without polluting Bob's workspace awareness

**Todo List:**
1. Read the existing `lab.md` content (requires bypassing `.bobignore` via direct shell read, as already done during planning)
2. Rewrite `lab.md` with the following top-level sections:
   - Overview
   - Prerequisites
   - Part 1: Setting Up Your Environment (install Ansible — Agent mode)
   - Part 2: Creating the Application (Bob generates the Node.js app — Agent mode)
   - Part 3: Containerizing the Application (Bob generates the Dockerfile — Agent mode)
   - Part 4: Installing Podman (switch to `⚡ Ansible Developer` mode — `podman_setup` role + `setup.yml`)
   - Part 5: Deploying with Ansible (`deploy_app` role + `deploy.yml`)
   - Verification
3. Each section should include a brief conceptual note (1–3 sentences) explaining what is happening and why, followed by the Bob prompt the student will use
4. Bob prompts must be in fenced code blocks labeled `txt`

**Relevant Context:**
- File: `Ansible Lab/Lab Instructions/lab.md` (currently blocked by `.bobignore` — write via shell or direct file tool with awareness of the restriction)
- Existing content to preserve/extend: the Ansible install prompt already written
- `.bobignore` at `Ansible Lab/.bobignore` contains `Lab Instructions` — this is intentional to keep instructions out of Bob's code context

---

### Task 2 — Write Part 1: Environment Setup (Install Ansible)

**Status:** `[x] done`

**Intent:**
Complete the first lab section. The student uses Bob to install Ansible on the RHEL VM. This establishes the pattern for the rest of the lab: read the concept note, send the prompt to Bob, observe what Bob does.

**Expected Outcomes:**
- `lab.md` Part 1 section is fully written
- Includes a 2–3 sentence explanation of why Ansible is needed before installing Podman
- Includes the Bob prompt (already drafted in the current `lab.md`)
- Includes a brief note on what the student should observe after Bob runs the command

**Todo List:**
1. Incorporate the existing Ansible install prompt from the current `lab.md`
2. Add context: explain Ansible's role as the automation layer that manages both environment setup and deployment
3. Add a "What to observe" callout after the prompt: student should see `ansible --version` output confirming a successful install
4. Keep the section under one page of reading

**Relevant Context:**
- Existing prompt: `Install Ansible on this Red Hat Enterprise Linux machine using sudo dnf install -y ansible, then run ansible --version to confirm it installed successfully.`
- This is already the correct prompt — retain it verbatim

---

### Task 3 — Write Part 2: Creating the Application

**Status:** `[x] done`

**Intent:**
Guide the student to use Bob in default Agent mode to generate a minimal Node.js/Express REST API. The application itself is simple — one route is sufficient. The focus is on how Bob scaffolds a real project from a natural-language description. The lab should explicitly confirm the student is in Agent mode at the start of this section.

**Expected Outcomes:**
- `lab.md` Part 2 section is fully written
- Explains that Bob will generate `package.json`, `index.js` (or equivalent), and a brief README
- Includes the Bob prompt the student sends
- Explains what the generated files do and why they matter for containerization
- Specifies the expected directory structure that Bob should create inside `Ansible Lab/app/`

**Todo List:**
1. Write the conceptual note: introduce what the application does (simple REST API, e.g., GET /health returns `{ "status": "ok" }`)
2. Write the Bob prompt:
   - Ask Bob to create a minimal Node.js/Express REST API in an `app/` directory
   - Specify: one GET `/health` endpoint returning `{ "status": "ok" }`, a `package.json` with a `start` script, and a `.gitignore` excluding `node_modules`
3. Add a note explaining why the app is intentionally minimal — the lab's value is the workflow, not the application
4. Show the expected resulting file tree after this step

**Relevant Context:**
- Target directory: `Ansible Lab/app/`
- Keep the application scope to exactly what is needed to produce a running container — nothing more

---

### Task 4 — Write Part 3: Containerizing the Application

**Status:** `[x] done`

**Intent:**
Guide the student to use Bob in default Agent mode to generate a Dockerfile for the Node.js app. This section introduces container concepts at a surface level and shows Bob generating production-appropriate container configuration. The lab should confirm Agent mode is still active.

**Expected Outcomes:**
- `lab.md` Part 3 section is fully written
- Includes a brief explanation of what a Dockerfile is and why containerization matters
- Includes the Bob prompt to generate the Dockerfile
- Explains key Dockerfile choices Bob makes (e.g., why `node:alpine`, why `COPY package*.json` before `COPY .`, what `EXPOSE` does)
- The Dockerfile should be placed at `Ansible Lab/app/Dockerfile`

**Todo List:**
1. Write a 2–3 sentence primer on containers and Dockerfiles for the target audience
2. Write the Bob prompt:
   - Ask Bob to write a Dockerfile for the Node.js app in the `app/` directory
   - Specify: use an official Node Alpine base image, copy and install dependencies first, then copy source, expose port 3000, and set the start command
3. After the prompt, add an "Understanding the Dockerfile" subsection explaining each instruction in plain language — this is where the lab teaches container fundamentals
4. Note that this Dockerfile will be used by Ansible to build the image on the VM

**Relevant Context:**
- Target file: `Ansible Lab/app/Dockerfile`
- Alpine base is preferred for size; port 3000 is the Express default

---

### Task 5 — Write Part 4: Installing Podman

**Status:** `[x] done`

**Intent:**
Guide the student to switch to `⚡ Ansible Developer` mode and use it to generate a `podman_setup` Ansible role and a thin `setup.yml` playbook that calls it. This section introduces Ansible roles as the primary unit of reusable automation and explains why roles are preferable to monolithic playbooks. The role installs both Podman and the `containers.podman` collection so subsequent work can use proper collection modules.

**Expected Outcomes:**
- `lab.md` Part 4 section is fully written
- Explains the mode switch to `⚡ Ansible Developer` and why it improves Ansible output quality
- Introduces Ansible roles — what they are, how they differ from inline tasks, and why modularity matters
- Includes a Bob prompt to generate the `podman_setup` role under `Ansible Lab/roles/podman_setup/`
- The role's `tasks/main.yml` installs Podman via `ansible.builtin.dnf` and installs the `containers.podman` collection via `ansible.builtin.command` (using `ansible-galaxy collection install`)
- Includes a Bob prompt to generate `playbooks/setup.yml` — a thin playbook that only declares hosts and calls the role
- Includes a prompt to execute `ansible-playbook playbooks/setup.yml`
- Explains the `ansible.builtin.dnf` module and `ansible-galaxy collection install` step

**Todo List:**
1. Add a mode-switch instruction: tell the student to switch Bob to `⚡ Ansible Developer` and explain the domain-specific benefit
2. Write the conceptual note: introduce Ansible roles — directory structure (`tasks/`, `handlers/`, `defaults/`, `meta/`), single-responsibility principle, and how a playbook calls a role
3. Write the Bob prompt to generate the `podman_setup` role:
   - Create the role at `roles/podman_setup/` using `ansible-galaxy role init` or by creating the directory structure directly
   - `tasks/main.yml` should: install Podman with `ansible.builtin.dnf`, run `podman --version` to verify, install `containers.podman` collection via `ansible.builtin.command` calling `ansible-galaxy collection install containers.podman`
   - Use `become: true` for privilege escalation on dnf tasks
4. Write the Bob prompt to generate `playbooks/setup.yml`:
   - Target `localhost`, `connection: local`
   - Call the `podman_setup` role — nothing else
5. Write the prompt to execute the playbook and observe output
6. Add "What to observe" note: Podman version in task output; collection install success message

**Relevant Context:**
- Target files: `Ansible Lab/roles/podman_setup/tasks/main.yml`, `Ansible Lab/playbooks/setup.yml`
- Custom mode: `⚡ Ansible Developer` (defined in `Ansible Lab/.bob/custom_modes.yaml`) — its instructions already prefer roles and built-in modules
- The `containers.podman` collection must be installed before the deploy role can use `containers.podman.podman_image` and `containers.podman.podman_container`

---

### Task 6 — Write Part 5: Deploying with Ansible

**Status:** `[x] done`

**Intent:**
The culminating section. The student remains in `⚡ Ansible Developer` mode and generates a `deploy_app` Ansible role and a thin `deploy.yml` playbook. The role uses `containers.podman` collection modules (now available after Part 4) to build the image and run the container. This demonstrates both Ansible as a container lifecycle manager and the payoff of the modular roles approach — the deploy role is a clean, self-contained unit.

**Expected Outcomes:**
- `lab.md` Part 5 section is fully written
- Opens by connecting back to the roles pattern established in Part 4 — reinforcing why modularity matters
- Includes a Bob prompt to generate the `deploy_app` role under `Ansible Lab/roles/deploy_app/`
- The role's `tasks/main.yml` uses `containers.podman.podman_image` to build the image and `containers.podman.podman_container` to run it
- Includes a Bob prompt to generate `playbooks/deploy.yml` — a thin playbook that calls the `deploy_app` role
- Includes a prompt to execute `ansible-playbook playbooks/deploy.yml`
- Explains idempotency and how the `containers.podman` modules handle it natively
- Student verifies with `curl http://localhost:3000/health`

**Todo List:**
1. Write the conceptual note: Ansible managing the full container lifecycle; how the `containers.podman` collection modules differ from raw shell commands (idempotent, declarative state)
2. Write the Bob prompt to generate the `deploy_app` role:
   - Create the role at `roles/deploy_app/`
   - `defaults/main.yml` should define: `app_image_name: my-api`, `app_image_tag: latest`, `app_src_path` pointing to the `app/` directory, `host_port: 3000`, `container_port: 3000`, `container_name: my-api`
   - `tasks/main.yml` should: build the image with `containers.podman.podman_image` (using `path` to the Dockerfile directory), run the container with `containers.podman.podman_container` (state: started, ports mapped, auto-remove disabled)
3. Write the Bob prompt to generate `playbooks/deploy.yml`:
   - Target `localhost`, `connection: local`
   - Call the `deploy_app` role — nothing else
4. Write the prompt to execute the playbook
5. Add explanation of idempotency: how `containers.podman` modules declare desired state rather than issuing imperative commands; re-running the playbook is safe
6. Add "What to observe" note: container running (`podman ps`), then `curl http://localhost:3000/health` returns `{"status":"ok"}`

**Relevant Context:**
- Target files: `Ansible Lab/roles/deploy_app/tasks/main.yml`, `Ansible Lab/roles/deploy_app/defaults/main.yml`, `Ansible Lab/playbooks/deploy.yml`
- `containers.podman` collection is guaranteed available after Part 4 completes — use collection modules directly, no fallback needed
- Role defaults make the role reusable — variables can be overridden per environment without editing the role itself
- The `app_src_path` variable must resolve correctly relative to the playbook execution directory; the prompt should instruct Bob to use an absolute path or `playbook_dir` Ansible magic variable

---

### Task 7 — Write the Verification Section

**Status:** `[x] done`

**Intent:**
Give the student a clear checklist to confirm the entire lab completed successfully. This is the lab's "definition of done."

**Expected Outcomes:**
- `lab.md` ends with a Verification section listing all observable success criteria
- Criteria are concrete and command-based, not subjective

**Todo List:**
1. Write a verification checklist covering:
   - `ansible --version` returns output (Part 1)
   - App files exist at `Ansible Lab/app/` (Part 2)
   - `Ansible Lab/app/Dockerfile` exists (Part 3)
   - `podman --version` returns output (Part 4)
   - `curl http://localhost:3000/health` returns `{"status":"ok"}` (Part 5)
2. Add a brief closing paragraph: what the student has demonstrated by completing the lab

**Relevant Context:**
- Verification steps should be runnable as-is in the terminal, no modification needed

---

### Task 8 — Create Starter Scaffold Files

**Status:** `[x] done`

**Intent:**
Create the empty directory placeholders and any starter files the lab references so the student workspace is in the correct initial state before beginning. This prevents confusion when Bob is asked to write files into directories that don't yet exist.

**Expected Outcomes:**
- `Ansible Lab/app/.gitkeep` exists (empty placeholder for the app directory)
- `Ansible Lab/playbooks/.gitkeep` exists (empty placeholder for playbooks)
- `Ansible Lab/roles/.gitkeep` exists (empty placeholder for the roles directory)
- A top-level `README.md` in `Ansible Lab/` briefly explains the lab purpose and points to `Lab Instructions/lab.md`

**Todo List:**
1. Create `Ansible Lab/app/.gitkeep`
2. Create `Ansible Lab/playbooks/.gitkeep`
3. Create `Ansible Lab/roles/.gitkeep`
4. Write `Ansible Lab/README.md` with: one-paragraph description of the lab, prerequisite (RHEL VM with internet access), pointer to `Lab Instructions/lab.md`

**Relevant Context:**
- `.gitkeep` files are conventional empty placeholders for empty tracked directories
- The `README.md` should not duplicate the lab instructions — it's a short entry point only
- The `roles/` directory is where both `podman_setup` and `deploy_app` roles will be generated by Bob during the lab
