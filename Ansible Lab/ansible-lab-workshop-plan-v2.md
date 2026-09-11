# Ansible Lab Workshop Plan (v2)

## Overview

Build a self-contained workshop inside the `Ansible Lab` directory that teaches developers how to use IBM Bob's AI-assisted workflow to provision a RHEL VM, create a Node.js/Express REST API, containerize it, and deploy it with Ansible and Podman — entirely on a single local VM.

The student interacts with Bob throughout using natural-language prompts. Bob generates all project files. The student's job is to understand what Bob creates and why.

**Core teaching goal:** Ansible installs *everything* except Ansible itself. Node.js, Podman, the `containers.podman` collection, and the container lifecycle are all managed declaratively through Bob-generated Ansible roles.

---

## Key Constraints and Design Decisions

| Constraint | Decision |
|---|---|
| Single RHEL VM, no external registry | Image is built and run locally; `podman ps` and `curl localhost:3000` are the only verification surface |
| Ansible installs all dependencies | Node.js, npm, Podman, and the `containers.podman` collection are installed by a Bob-generated `setup.yml` composing multiple roles |
| Ansible itself must be bootstrapped manually | Part 1 explicitly frames this chicken-and-egg problem — it is a teaching moment, not a gap |
| Roles over monolithic playbooks | Three roles: `nodejs`, `podman`, `deploy_app`. Playbooks are thin entry points only |
| Playbooks live in `playbooks/` | `ansible.cfg` sets `roles_path = ./roles`; all commands are run from the project root |
| Container build file is named `Dockerfile` | Podman reads it natively; the name is familiar to developers |
| Access is VM-local only | No firewall configuration needed; all verification is `curl` from the VM itself |
| Mode usage | Provisioning and deployment use `⚡ Ansible Developer`; application and container authoring use default Agent mode |
| Audience | Developers with basic Linux/terminal familiarity, new to Ansible and containers |
| Target duration | ~90 minutes |

---

## Structural Changes from v1 (and why)

1. **Provisioning moved before application development.** v1 asked the student to create a Node.js app (Part 2) before Node.js was ever installed — and Node.js was never installed at all. Provisioning the VM first mirrors real-world practice, gives Node.js a purpose, and lets the student run the app locally before containerizing it.
2. **`setup.yml` now composes two roles instead of one.** A playbook that calls a single role does not demonstrate why roles exist. Calling `nodejs` and `podman` from one playbook teaches composition and single-responsibility at the same time.
3. **Added an explicit local-run step.** After Bob generates the app, the student runs `npm install && npm start` and curls it. This proves the Ansible-installed Node.js works and gives an early win before container concepts are introduced.
4. **Added `ansible.cfg` and `inventory.ini` to the scaffold.** v1 relied on implicit localhost, which emits warnings and skips a core Ansible concept. A three-line inventory teaches the idea cheaply. `ansible.cfg` is also what makes the `playbooks/` layout work.
5. **Fixed the role resolution path.** In v1, `playbooks/setup.yml` calling a role in `Ansible Lab/roles/` would fail — Ansible searches `<playbook_dir>/roles`, which resolves to `playbooks/roles/`. Setting `roles_path = ./roles` in `ansible.cfg` fixes this and doubles as a teaching point about Ansible configuration.
6. **Added idempotency demonstration as a first-class step.** Re-running each playbook and observing `changed=0` is the single most persuasive moment in an Ansible workshop. v1 mentioned idempotency only as prose.
7. **Added teardown and troubleshooting sections.** Workshops get re-run and students get stuck; both need a scripted path.
8. **Added a reference-solution appendix.** Bob's output varies between runs. Instructors need known-good file contents to unblock students without debugging live.

---

## Final Repository Layout

```
Ansible Lab/
├── README.md
├── .bobignore
├── ansible.cfg
├── inventory.ini
├── playbooks/
│   ├── setup.yml                   # thin: calls nodejs + podman roles
│   └── deploy.yml                  # thin: calls deploy_app role
├── roles/
│   ├── nodejs/
│   │   ├── defaults/main.yml
│   │   └── tasks/main.yml
│   ├── podman/
│   │   ├── defaults/main.yml
│   │   └── tasks/main.yml
│   └── deploy_app/
│       ├── defaults/main.yml
│       └── tasks/main.yml
├── app/
│   ├── package.json
│   ├── index.js
│   ├── Dockerfile
│   └── .gitignore
└── Lab Instructions/
    ├── lab.md
    └── reference-solutions.md
```

All `ansible-playbook` commands are run from `Ansible Lab/` so that `ansible.cfg` is picked up.

---

## Lab Flow at a Glance

| Part | Bob Mode | Student Builds | Proves |
|---|---|---|---|
| 1 | Agent | Ansible installed via dnf | Bootstrap; why Ansible can't install itself |
| 2 | ⚡ Ansible Developer | `nodejs` + `podman` roles, `playbooks/setup.yml` | Roles, composition, `dnf` module, collections, idempotency |
| 3 | Agent | Express API in `app/` | Node.js install worked; app runs locally |
| 4 | Agent | `app/Dockerfile` | Container fundamentals, layer caching |
| 5 | ⚡ Ansible Developer | `deploy_app` role, `playbooks/deploy.yml` | Ansible as container lifecycle manager; declarative state |
| 6 | — | Verification + teardown | Definition of done; repeatability |

Mode switches: Part 2 (Agent → Ansible Developer), Part 3 (back to Agent), Part 5 (back to Ansible Developer). Each switch must be called out explicitly in the instructions with a one-sentence reason, so it reads as intentional rather than fussy.

---

## Authoring Conventions (apply to every lab section)

Every Part in `lab.md` uses the same six-block template. This consistency is what makes a workshop followable under time pressure.

1. **Objective** — one sentence, what the student will have when the Part ends.
2. **Mode** — which Bob mode, and one sentence on why.
3. **Concept** — 2–4 sentences of plain-language background. No jargon without definition.
4. **Prompt** — the exact text the student sends Bob, in a fenced ` ```txt ` block. Self-contained, copy-pasteable, explicit about file paths.
5. **Expected result** — the file tree or command output the student should end up with. Describe outcomes, not exact file contents (Bob's output varies).
6. **What to observe** — the one or two things that matter pedagogically, phrased as an instruction to look at something specific.

Additional rules:
- Prompts must name paths relative to the project root (`roles/podman/tasks/main.yml`, not "the podman role").
- Prompts must state the *outcome* wanted, not dictate YAML line by line — otherwise the lab teaches transcription, not AI-assisted development.
- Every terminal command in the lab assumes the student's working directory is `Ansible Lab/`. State this once in Prerequisites and repeat it at the top of Part 2.
- No emojis except the `⚡` in the mode name. No filler prose.
- Troubleshooting notes go in an indented block at the end of a Part, not inline, so the happy path stays readable.

---

## Sub-Tasks

---

### Task 1 — Create the Lab Instruction File Structure

**Status:** `[ ] pending`

**Intent:**
Establish the final `lab.md` skeleton — sections, headings, and the six-block template — so subsequent tasks slot content into place cleanly.

**Expected Outcomes:**
- `Ansible Lab/Lab Instructions/lab.md` contains a complete skeleton with placeholder content per section
- Structure: Title → Overview → Learning Objectives → Prerequisites → Lab Flow table → Parts 1–5 → Verification → Teardown → Troubleshooting
- The six-block template from *Authoring Conventions* is applied consistently

**Todo List:**
1. Read existing `lab.md` via direct shell read (bypasses `.bobignore`)
2. Write the skeleton with all headings and the flow table
3. Write the Prerequisites section: RHEL 9 VM with internet access and sudo rights, IBM Bob installed and connected, terminal access, ~90 minutes, and the working-directory convention (`Ansible Lab/`)
4. Write Learning Objectives (4–5 bullets): explain what an Ansible role is; use Bob to generate roles and playbooks; provision a host declaratively; build and run a container with Ansible; explain idempotency
5. Insert the Lab Flow table from this plan

**Relevant Context:**
- `Ansible Lab/.bobignore` contains `Lab Instructions` — intentional, keeps instructions out of Bob's code context
- Reference solutions (Task 11) also live under `Lab Instructions/` so Bob cannot read ahead

---

### Task 2 — Create the Project Scaffold

**Status:** `[ ] pending`

**Intent:**
Put the workspace in the correct initial state so Bob is never asked to write into a directory that does not exist, and so Ansible resolves roles and inventory without configuration surprises. Moved earlier than v1 because Part 2 depends on it.

**Expected Outcomes:**
- `Ansible Lab/app/.gitkeep`, `Ansible Lab/roles/.gitkeep`, and `Ansible Lab/playbooks/.gitkeep` exist
- `Ansible Lab/ansible.cfg` exists and sets `roles_path`
- `Ansible Lab/inventory.ini` exists
- `Ansible Lab/README.md` exists — short entry point only, pointing to `Lab Instructions/lab.md`

**Todo List:**
1. Create `.gitkeep` placeholders in `app/`, `roles/`, and `playbooks/`
2. Write `ansible.cfg`:
   ```ini
   [defaults]
   inventory = inventory.ini
   roles_path = ./roles
   stdout_callback = yaml
   interpreter_python = auto_silent
   ```
3. Write `inventory.ini`:
   ```ini
   [local]
   localhost ansible_connection=local
   ```
4. Write `README.md`: one paragraph on lab purpose, prerequisite line, pointer to the instructions
5. Add a short subsection to `lab.md` Prerequisites explaining `ansible.cfg` and `inventory.ini` — two sentences each, plus one sentence on why commands must be run from the project root

**Relevant Context:**
- **`roles_path` is load-bearing.** Because the playbooks live in `playbooks/`, Ansible's default search (`<playbook_dir>/roles`) will not find the roles. `roles_path = ./roles` in `ansible.cfg` is what makes the layout work.
- **`ansible.cfg` is only read from the current working directory** (or `ANSIBLE_CONFIG`). If a student runs `ansible-playbook` from inside `playbooks/`, the config is ignored and roles will not resolve. This must be stated in Prerequisites and appear in Troubleshooting.
- `stdout_callback = yaml` makes task output dramatically more readable for beginners; worth the one line
- `interpreter_python = auto_silent` suppresses a warning that confuses first-time users

---

### Task 3 — Write Part 1: Bootstrap Ansible

**Status:** `[ ] pending`

**Intent:**
The student installs Ansible using Bob in Agent mode. Frame this as the one manual step: Ansible cannot install itself, so this is the bootstrap. Everything after this point is automated.

**Expected Outcomes:**
- Part 1 fully written
- Explains the bootstrap/chicken-and-egg framing in 2–3 sentences
- Includes the Bob prompt
- Student ends with a working `ansible --version`

**Todo List:**
1. Write the Concept block: Ansible is the automation layer for everything that follows; it is the only thing installed by hand
2. Write the Bob prompt. Recommended wording:
   ```txt
   Install Ansible on this Red Hat Enterprise Linux machine using
   sudo dnf install -y ansible-core, then run ansible --version to
   confirm it installed successfully.
   ```
3. Add a one-sentence note explaining `ansible-core` vs the full `ansible` package
4. What to observe: version output, and the config file line (it will say "None" here, which sets up the `ansible.cfg` discussion in Part 2)

**Relevant Context:**
- **Correction from v1:** v1 used `dnf install -y ansible`. On RHEL 9, the full community `ansible` package is not in the standard AppStream repositories — `ansible-core` is the supported package. Using `ansible` risks a failed install on a clean RHEL VM and derails the workshop at minute five.
- Using `ansible-core` also has a pedagogical benefit: it ships with builtin modules only, which makes the explicit `containers.podman` collection install in Part 2 genuinely necessary rather than a no-op. If the full `ansible` package were used, the collection would already be present and the lesson would be hollow.
- Verify the exact package availability on the target RHEL image before finalizing (Task 12)

---

### Task 4 — Write Part 2: Provision the VM with Ansible

**Status:** `[ ] pending`

**Intent:**
The centerpiece of the Ansible teaching. The student switches to `⚡ Ansible Developer` mode and has Bob generate two single-responsibility roles — `nodejs` and `podman` — plus a thin `playbooks/setup.yml` that composes both. Running it provisions every remaining dependency.

**Expected Outcomes:**
- Part 2 fully written
- Explains the mode switch and why a domain-specific mode produces better Ansible output
- Introduces roles: directory structure, single responsibility, how a playbook calls them, why this beats a monolithic playbook
- Three Bob prompts: generate `nodejs` role, generate `podman` role, generate `playbooks/setup.yml`
- A run instruction, executed from the project root
- An idempotency demonstration: run it a second time and observe `changed=0`

**Todo List:**
1. Write the mode-switch instruction with a one-sentence rationale
2. Write the Concept block on roles: `tasks/`, `defaults/`, `handlers/`, `meta/`; what each is for; that this lab uses only `tasks/` and `defaults/`
3. Restate the working-directory rule: all `ansible-playbook` commands run from `Ansible Lab/`, because that is where `ansible.cfg` lives
4. Write prompt 1 — `nodejs` role at `roles/nodejs/`:
   - `tasks/main.yml` installs `nodejs` and `npm` with `ansible.builtin.dnf`, `become: true`
   - Registers and displays `node --version` and `npm --version` using `ansible.builtin.command` with `changed_when: false`
   - `defaults/main.yml` defines the package list so it is overridable
5. Write prompt 2 — `podman` role at `roles/podman/`:
   - `tasks/main.yml` installs `podman` with `ansible.builtin.dnf`, `become: true`
   - Verifies with `podman --version`, `changed_when: false`
   - Installs the `containers.podman` collection with `ansible.builtin.command` running `ansible-galaxy collection install containers.podman`, **with `become: false`** and a `creates:` guard
6. Write prompt 3 — `playbooks/setup.yml`: targets the `local` group, lists both roles under `roles:`, and nothing else
7. Write the run instruction: `ansible-playbook playbooks/setup.yml`
8. Write the idempotency step: run it again, observe the PLAY RECAP, explain what `changed=0` means
9. Write "What to observe": node/npm/podman versions in task output; collection install message; the second run's recap
10. Write troubleshooting notes (see Relevant Context)

**Relevant Context:**
- **Critical gotcha — collection install path.** If the `ansible-galaxy collection install` task runs under `become: true`, the collection installs into `/root/.ansible/collections` and will be invisible when the student runs `deploy.yml` as their normal user. The prompt must explicitly require `become: false` on that task. This is the single most likely failure point in the lab.
- **Idempotency guard.** `ansible.builtin.command` always reports `changed`. To make the second run show `changed=0`, the collection task needs `creates: "{{ ansible_env.HOME }}/.ansible/collections/ansible_collections/containers/podman"`. Without this, the idempotency demonstration in step 8 fails and undercuts the lesson. Note that `community.general.ansible_galaxy_install` is the cleaner module but is unavailable under `ansible-core`.
- **Scope `become` narrowly.** Only the `dnf` tasks need privilege escalation. Do not set `become: true` at the play level — doing so makes the later Podman container tasks run rootful, which contradicts the rootless story in Part 5.
- **Node.js version.** RHEL 9 AppStream ships a default nodejs module stream. If a specific major version is needed, the role must enable the stream first. Keep the default unless Task 12 shows it is too old for Express 4.
- Target files: `roles/nodejs/`, `roles/podman/`, `playbooks/setup.yml`

---

### Task 5 — Write Part 3: Create and Run the Application

**Status:** `[ ] pending`

**Intent:**
The student switches back to Agent mode and has Bob scaffold a minimal Express API, then runs it locally. The local run is what makes the Node.js installation in Part 2 meaningful, and it establishes a known-working baseline before containers are introduced.

**Expected Outcomes:**
- Part 3 fully written
- Explains the switch back to Agent mode
- One Bob prompt generating the full app
- Explicit local-run instructions and a successful `curl`
- Explains why the app is deliberately trivial

**Todo List:**
1. Write the Concept block: the app is a vehicle, not the lesson; one endpoint is enough to prove the pipeline end to end
2. Write the Bob prompt — create in `app/`:
   - `index.js` with Express, one `GET /health` returning `{ "status": "ok" }`
   - Port read from `process.env.PORT` with a default of `3000` (so the container can override it later without code changes — worth one sentence of explanation)
   - `package.json` with a `start` script and Express as a dependency
   - `.gitignore` excluding `node_modules`
3. Write the local run steps: `cd app`, `npm install`, `npm start`, then in a second terminal `curl http://localhost:3000/health`
4. Add an instruction to stop the process with Ctrl+C and `cd ..` before continuing — otherwise port 3000 is occupied when the container starts in Part 5, and the student is no longer in the project root
5. Show the expected file tree
6. What to observe: `node_modules/` appears (and is gitignored); the curl response

**Relevant Context:**
- Target directory: `Ansible Lab/app/`
- **New in v2:** the "stop the dev server and return to the project root" instruction. A student who leaves `npm start` running will hit a port bind failure in Part 5 and blame Ansible; a student who stays in `app/` will lose `ansible.cfg`.
- Keep app scope to exactly what produces a running container — no routers, no middleware, no tests

---

### Task 6 — Write Part 4: Containerize the Application

**Status:** `[ ] pending`

**Intent:**
Still in Agent mode, the student has Bob write a `Dockerfile`. This Part is where container fundamentals are actually taught — the line-by-line explanation matters more than the generation.

**Expected Outcomes:**
- Part 4 fully written
- 2–3 sentence primer on images vs containers, and what a Dockerfile is
- One Bob prompt generating `app/Dockerfile`
- An "Understanding the Dockerfile" subsection explaining every instruction in plain language
- An optional manual `podman build` + `podman run` step to contrast imperative with declarative

**Todo List:**
1. Write the container primer for an audience that has never used containers
2. Write the Bob prompt — create `app/Dockerfile`:
   - Official Node Alpine base image, pinned to a major version
   - `WORKDIR /app`
   - Copy `package*.json` and run `npm install` before copying source
   - Copy the rest of the source
   - `EXPOSE 3000`
   - `CMD ["npm", "start"]`
3. Write "Understanding the Dockerfile" — cover, in order: what a base image is; why Alpine (size); why dependencies are copied and installed before source (layer caching — the highest-value concept in this section); what `EXPOSE` does and does not do (documentation, not publishing); what `CMD` is
4. Add a one-sentence aside that Podman builds Dockerfiles natively and that `Containerfile` is the same format under a vendor-neutral name — students will encounter both, and this pre-empts the question
5. Optional contrast step: from `app/`, run `podman build -t my-api:latest .` then `podman run -d -p 3000:3000 --name my-api my-api:latest`, then `podman stop my-api && podman rm my-api`. Frame it as "this is the manual version of what Ansible will do next" — it makes Part 5's value obvious
6. Note that Ansible will consume this file to build the image on the VM

**Relevant Context:**
- Target file: `Ansible Lab/app/Dockerfile`
- If the optional manual build is included, the instructions **must** include the stop/remove commands and a reminder to `cd ..` afterwards, or Part 5 will fail on a container name collision
- Pin the base image major version; an unpinned `node:alpine` makes the lab non-reproducible across workshop runs
- This is the first cut candidate if Task 12 shows the lab running over 90 minutes

---

### Task 7 — Write Part 5: Deploy with Ansible

**Status:** `[ ] pending`

**Intent:**
The culminating section. Back in `⚡ Ansible Developer` mode, the student generates a `deploy_app` role that builds the image and runs the container using `containers.podman` collection modules, plus a thin `playbooks/deploy.yml`. This demonstrates Ansible as a container lifecycle manager and pays off the modular-roles argument from Part 2.

**Expected Outcomes:**
- Part 5 fully written
- Opens by connecting back to the roles pattern from Part 2
- Bob prompt generating the `deploy_app` role with a populated `defaults/main.yml`
- Bob prompt generating `playbooks/deploy.yml`
- Run instruction and successful `curl`
- Explains idempotency and declarative state honestly, including its limits

**Todo List:**
1. Write the Concept block: declarative desired state vs imperative commands; how the collection modules differ from `shell: podman run ...`
2. Write the prompt for the `deploy_app` role at `roles/deploy_app/`:
   - `defaults/main.yml`: `app_image_name: my-api`, `app_image_tag: latest`, `app_src_path: "{{ playbook_dir | dirname }}/app"`, `container_name: my-api`, `host_port: 3000`, `container_port: 3000`
   - `tasks/main.yml`: build with `containers.podman.podman_image` (`name`, `tag`, `path: "{{ app_src_path }}"`, `state: present`), then run with `containers.podman.podman_container` (`name`, `image`, `state: started`, `ports: ["{{ host_port }}:{{ container_port }}"]`, `recreate: true`)
   - No `become` — the container runs rootless as the student's user
3. Write the prompt for `playbooks/deploy.yml`: targets `local`, calls `deploy_app`, nothing else
4. Write the run instruction: `ansible-playbook playbooks/deploy.yml`, from the project root
5. Write the verification: `podman ps`, then `curl http://localhost:3000/health`
6. Write the idempotency block — and be honest about the nuance: re-running shows the container already in the desired state, but `podman_image` will not rebuild automatically when application source changes. Explain `force: true` as the lever, and why a real pipeline would use a changing tag instead. This nuance is worth teaching; glossing over it produces students who trust idempotency too much.
7. Write "What to observe": the PLAY RECAP; `podman ps` output including the port mapping; the curl response

**Relevant Context:**
- Target files: `roles/deploy_app/tasks/main.yml`, `roles/deploy_app/defaults/main.yml`, `playbooks/deploy.yml`
- **Path resolution:** because playbooks live in `playbooks/`, `{{ playbook_dir }}` resolves to `Ansible Lab/playbooks`. Use `{{ playbook_dir | dirname }}/app` rather than `{{ playbook_dir }}/../app` — same result, no `..` for students to puzzle over, and it reinforces that Ansible variables support filters. Explain this line explicitly in the instructions; it is the one piece of Jinja in the lab.
- `recreate: true` keeps the lab reliable across repeated runs at the cost of strict idempotency on the container task. State this tradeoff in the instructions rather than hiding it — alternatively omit it and require teardown before re-running
- Rootless Podman binds host port 3000 without privilege; no `become` is needed and adding it would create a root-owned container invisible to the student's `podman ps`
- The `containers.podman` collection is guaranteed present after Part 2 — no fallback path needed

---

### Task 8 — Write the Verification Section

**Status:** `[ ] pending`

**Intent:**
A concrete, command-based definition of done.

**Expected Outcomes:**
- `lab.md` includes a verification checklist with commands and expected output side by side
- Every criterion is objectively checkable

**Todo List:**
1. Write the checklist as a table: Command | Expected output | Part
   - `ansible --version` → version string (Part 1)
   - `node --version` and `podman --version` → version strings (Part 2)
   - `ansible-galaxy collection list containers.podman` → collection listed (Part 2)
   - `ls app/` → `index.js`, `package.json`, `Dockerfile` present (Parts 3–4)
   - `podman images` → `my-api:latest` present (Part 5)
   - `podman ps` → container running, `0.0.0.0:3000->3000/tcp` (Part 5)
   - `curl http://localhost:3000/health` → `{"status":"ok"}` (Part 5)
2. Note that all commands are run from `Ansible Lab/`
3. Write a short closing paragraph on what the student has demonstrated: a full provision-to-deploy pipeline authored through natural language, with every dependency installed declaratively

---

### Task 9 — Write the Teardown and Reset Section

**Status:** `[ ] pending`

**Intent:**
Let students re-run the lab and let instructors reset a VM between sessions. New in v2.

**Expected Outcomes:**
- A teardown section with copy-pasteable commands
- Optional stretch: a Bob prompt to generate a `teardown.yml` playbook

**Todo List:**
1. Write manual teardown: `podman stop my-api`, `podman rm my-api`, `podman rmi my-api:latest`
2. Write full reset: the above plus `rm -rf app/node_modules`
3. Optional stretch prompt: ask Bob to generate `playbooks/teardown.yml` using `containers.podman.podman_container` with `state: absent` — a good self-directed exercise that reinforces declarative state

---

### Task 10 — Write the Troubleshooting Section

**Status:** `[ ] pending`

**Intent:**
Pre-empt the failures most likely to occur, so an instructor is not debugging live in front of twenty people. New in v2.

**Expected Outcomes:**
- A troubleshooting table: Symptom | Likely cause | Fix

**Todo List:**
1. Populate with the known failure modes:
   - `couldn't resolve module/action 'containers.podman.podman_image'` → collection installed under root → re-run the Part 2 collection task with `become: false`; verify with `ansible-galaxy collection list`
   - `the role 'deploy_app' was not found` → command run from outside the project root, so `ansible.cfg` and its `roles_path` were never loaded → `cd` to `Ansible Lab/` and retry; confirm with `ansible --version`, which prints the active config file path
   - `port is already allocated` / `address already in use` → the Part 3 dev server is still running, or a container from the optional manual build in Part 4 still exists → Ctrl+C the dev server; `podman ps -a`, then stop and remove
   - `No package ansible available` → wrong package name → use `ansible-core`
   - `curl: Connection refused` → container exited on startup → `podman logs my-api`
   - Second playbook run still shows `changed` on the collection task → missing `creates:` guard
2. Add a general instruction: run `ansible-playbook <playbook> -v` for more detail, and `podman logs <name>` for container failures
3. Add the single best diagnostic: `ansible --version` prints the config file in use — if it says `None`, the student is in the wrong directory

---

### Task 11 — Write the Reference Solutions Appendix

**Status:** `[ ] pending`

**Intent:**
Bob's generated output varies between runs. Instructors need known-good versions of every file to compare against or fall back to. New in v2.

**Expected Outcomes:**
- `Ansible Lab/Lab Instructions/reference-solutions.md` contains the full contents of every file Bob is expected to generate
- Clearly framed as a reference, not as something the student copies

**Todo List:**
1. Include final contents for: `roles/nodejs/tasks/main.yml`, `roles/podman/tasks/main.yml`, `playbooks/setup.yml`, `app/index.js`, `app/package.json`, `app/Dockerfile`, `roles/deploy_app/defaults/main.yml`, `roles/deploy_app/tasks/main.yml`, `playbooks/deploy.yml`
2. Also include `ansible.cfg` and `inventory.ini` for completeness, since a corrupted `ansible.cfg` breaks role resolution
3. Add a header note: these are one valid implementation; student output may differ and still be correct
4. Confirm the file sits under `Lab Instructions/` so `.bobignore` keeps it out of Bob's context

---

### Task 12 — Dry Run and Validate on a Clean VM

**Status:** `[ ] pending`

**Intent:**
Run the entire lab start to finish on a freshly provisioned RHEL VM, following only the written instructions. This is the task that actually determines whether the workshop works. New in v2.

**Expected Outcomes:**
- Every prompt produces usable output from Bob on the first attempt
- Every command in Verification passes
- Timings recorded per Part
- Package names and versions confirmed against the real RHEL image

**Todo List:**
1. Provision a clean RHEL 9 VM
2. Confirm `ansible-core` availability and version in the enabled repositories
3. Confirm the default `nodejs` module stream version and that it satisfies Express
4. Execute every Part verbatim, sending each prompt to Bob exactly as written
5. Deliberately test the wrong-directory failure: run `ansible-playbook` from inside `playbooks/` and confirm the Troubleshooting entry matches the real error text
6. Record where Bob's output deviates from expectations; tighten those prompts
7. Record per-Part timings; if total exceeds 90 minutes, cut the optional manual build in Part 4 first
8. Run teardown and repeat Parts 3–5 to confirm repeatability
9. Update `reference-solutions.md` with the file contents that actually worked

**Relevant Context:**
- Prompt tightening is the highest-value output of this task. A prompt that works in one session and not another is the main risk in an AI-assisted workshop
