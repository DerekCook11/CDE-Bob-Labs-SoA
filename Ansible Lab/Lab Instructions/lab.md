# Ansible Lab: AI-Assisted Application Development and Deployment

## Overview

This lab walks through using IBM Bob to create a Node.js REST API, containerize it, and deploy it with Ansible and Podman. All of this will be done on our single local RHEL VM. Ansible manages every infrastructure and deployment step after the initial bootstrap; Bob generates all project files through natural-language prompts.

The student's job is to write effective prompts, understand what Bob creates, and observe why it was built that way.

## Learning Objectives

By the end of this lab you will be able to:

- Explain what an Ansible role is and why roles are preferable to monolithic playbooks
- Use Bob to generate Ansible roles and playbooks from natural-language descriptions
- Provision a host declaratively using Ansible, installing Node.js, Podman, and a required collection
- Build and run a containerized application using Ansible and the `containers.podman` collection
- Explain idempotency and demonstrate it by re-running a playbook

---

## Prerequisites

- A RHEL 9 VM with internet access and `sudo` privileges
- IBM Bob installed and connected to this workspace
- Basic familiarity with the Linux terminal
- Estimated time: ~90 minutes

### Working Directory Convention

Whithin Bob, you will want to open the `Ansible Lab/` directory as your project root. This is so terminal commands and Bob actions are performed within this directory. Here your `ansible.cfg` lives. If you run `ansible-playbook` from any other directory, Ansible will not find `ansible.cfg`, roles will not resolve, and the playbooks will fail.


### Project Configuration Files

Two files in the project root configure how Ansible runs:

**`ansible.cfg`** tells Ansible where to find roles and inventory. The most important line is `roles_path = ./roles`. Because playbooks live in `playbooks/`, Ansible's default role search path (`<playbook_dir>/roles`) would resolve to `playbooks/roles/` — not where the roles actually are. This setting fixes that.

**`inventory.ini`** defines the target host. For this lab that is `localhost` with a local connection, which avoids SSH overhead and keeps the lab self-contained.

---

## Part 1: Bootstrap Ansible

**Objective:** Ansible is installed and `ansible --version` returns a version string.

Ansible is the automation layer for everything that follows. It is the only tool you will install by hand. This is an intentional bootstrap: Ansible cannot use itself to install itself, so the first step is manual. After this, our dependencies, Node.js, Podman, the `containers.podman` collection are to be installed by Bob-generated Ansible roles.

**Prompt:**

```txt
Install Ansible on this Red Hat Enterprise Linux machine using sudo dnf install -y ansible-core, then run ansible --version to confirm it installed successfully.
```

**Note:** The package is `ansible-core`, not `ansible`. On RHEL 9, `ansible-core` is the supported package in the standard AppStream repository. It ships with only the built-in modules, which is intentional — it makes the explicit `containers.podman` collection install in Part 2 genuinely necessary, not a no-op.

**What to observe:** The output of `ansible --version` will include a `config file` line that currently says `None`. That will change after Part 2 adds `ansible.cfg` to the project.

---

## Part 2: Provision the VM with Ansible

**Objective:** Node.js, npm, Podman, and the `containers.podman` collection are installed via two Ansible roles composed by a single playbook.


### Ansible Roles

For the provisioning work in this Part, you will use **Ansible roles** rather than writing tasks directly in a playbook.

A role is a self-contained, reusable unit of automation with a standard directory structure:

```
roles/
└── role_name/
 ├── tasks/ # What the role does (main.yml is the entry point)
 ├── defaults/ # Default variable values, easily overridden
 ├── handlers/ # Tasks triggered by notifications (e.g., service restarts)
 └── meta/ # Role metadata and dependencies
```

This lab uses only `tasks/` and `defaults/` in each role. A playbook that uses roles declares only which hosts to target and which roles to apply — all logic stays in the roles. This makes each role independently testable and reusable across playbooks and environments.

This Part calls two roles from one playbook. That composition is the point: each role has a single responsibility, and the playbook assembles them.

### Step 1 — Generate the nodejs Role

**Prompt:**

```txt
Using Ansible Developer best practices, create an Ansible role named nodejs under roles/nodejs/. The role should:
1. Define a default variable nodejs_packages in defaults/main.yml containing [nodejs, npm].
2. In tasks/main.yml, install the packages in nodejs_packages using ansible.builtin.dnf with become: true.
3. Verify the installation by running node --version and npm --version using ansible.builtin.command with changed_when: false, registering each result.
4. Print the versions using ansible.builtin.debug.
Add a comment above each task explaining what it does and why. Use fully-qualified module names throughout.
```

**Expected result:**

```
roles/nodejs/
├── defaults/
│ └── main.yml
└── tasks/
 └── main.yml
```

**What to observe:** The use of `changed_when: false` on the verification tasks. `ansible.builtin.command` always reports `changed` by default because Ansible cannot know whether a command modified state. Setting `changed_when: false` tells Ansible this task is read-only, which is accurate and keeps the PLAY RECAP honest.

### Step 2 — Generate the podman Role

**Prompt:**

```txt
Using Ansible Developer best practices, create an Ansible role named podman under roles/podman/. The role should:
1. Install podman using ansible.builtin.dnf with become: true.
2. Verify with podman --version using ansible.builtin.command with changed_when: false, registering and printing the result.
3. Install the containers.podman Ansible collection using ansible.builtin.command to run ansible-galaxy collection install containers.podman. This task must use become: false and must include a creates: guard pointing to ~/.ansible/collections/ansible_collections/containers/podman so the task is skipped if the collection is already present.
Add a comment above each task. Use fully-qualified module names throughout.
```

**Expected result:**

```
roles/podman/
├── defaults/
│ └── main.yml
└── tasks/
 └── main.yml
```

**What to observe:** The `creates:` guard on the collection install task. Without it, `ansible.builtin.command` always reports `changed` (because it cannot introspect the command's effect), the second run would re-install the collection, and the idempotency demonstration in Step 4 would be undermined.

Also note `become: false` on the collection install task. If it ran under `become: true`, the collection would install into `/root/.ansible/collections` and be invisible when the deploy playbook runs as your normal user. The `dnf` tasks need privilege escalation; the collection install does not.

### Step 3 — Generate the setup.yml Playbook

**Prompt:**

```txt
Create a playbook at playbooks/setup.yml. It should target the local group from inventory, list the nodejs and podman roles under roles:, and contain nothing else. All logic belongs in the roles.
```

**Expected result** — `playbooks/setup.yml` should be roughly 8–10 lines:

```
playbooks/
└── setup.yml
```

If the generated file contains inline tasks, ask Bob to move them into the appropriate role.

### Step 4 — Run and Verify

Run the playbook from the project root:

```txt
Run ansible-playbook playbooks/setup.yml from the Ansible Lab directory and confirm it completes without errors.
```

**What to observe:** Each task in both roles should complete with status `ok` or `changed`. The debug tasks will print the Node.js, npm, and Podman version strings. The collection install task will show `changed` on the first run.

### Step 5 — Demonstrate Idempotency

Run the playbook a second time:

```bash
ansible-playbook playbooks/setup.yml
```

Read the PLAY RECAP at the bottom of the output. The `changed` count should be `0`. Every package is already installed, every version check is marked `changed_when: false`, and the collection install task is skipped by its `creates:` guard.

This is idempotency: running the playbook again produces the same system state without making unnecessary changes. It is the property that makes Ansible safe to run repeatedly and the foundation of reliable automation.

> **Troubleshooting:** If `changed` is not 0 on the second run, the most likely cause is a missing `creates:` guard on the collection install task. Ask Bob to add one.

---

## Part 3: Create and Run the Application

**Objective:** A minimal Express API is running locally and responds to `curl http://localhost:3000/health`.

**Mode: Agent (default)**

Switch Bob back to the default Agent mode. The Ansible work for provisioning is complete; now you will use Bob to scaffold the application that will be containerized and deployed.

**To switch modes:** Open the mode selector in Bob and choose **Agent**.

The application is deliberately trivial — one endpoint, no middleware, no database. It is a vehicle for demonstrating the pipeline, not an application worth building. Keeping it minimal means any failure in Parts 4 or 5 is unambiguously an infrastructure problem, not an application problem.

### Generate the Application

**Prompt:**

```txt
Create a minimal Node.js Express REST API in the app/ directory. Requirements:
- One endpoint: GET /health returns { "status": "ok" } as JSON.
- The app listens on the port specified by the PORT environment variable, defaulting to 3000 if PORT is not set. Use const PORT = process.env.PORT || 3000.
- package.json includes express as a dependency and a "start" script that runs node index.js.
- .gitignore excludes node_modules/.
No other dependencies, no middleware, no additional routes.
```

**Expected result:**

```
app/
├── index.js
├── package.json
└── .gitignore
```

### Run It Locally

The Node.js installed by the `nodejs` role in Part 2 is what runs this application. Verify it works before moving on:

```bash
cd app
npm install
npm start
```

In a second terminal, from any directory:

```bash
curl http://localhost:3000/health
```

You should receive:

```json
{"status":"ok"}
```

**What to observe:** `node_modules/` appears in the `app/` directory after `npm install`. It is excluded by `.gitignore`. The `PORT` variable in `index.js` is why the container will be able to override the port without any code changes.

Before continuing, stop the dev server and return to the project root:

```bash
# In the terminal running npm start:
Ctrl+C

# Return to the project root:
cd ..
```

Stopping the server is required. If `npm start` is still running when the container starts in Part 5, both will compete for port 3000 and the container will fail to bind.

---

## Part 4: Containerize the Application

**Objective:** `app/Dockerfile` exists and describes how to build a container image for the Express API.

**Mode: Agent (default)**

A **container image** is a portable, self-contained package: the application, its runtime, and its dependencies, bundled together so it runs identically on any host with a container runtime. A **Dockerfile** is the recipe for building that image — a sequence of instructions specifying what to include and how to configure the container.

Podman reads Dockerfiles natively. The format is also called `Containerfile` in vendor-neutral contexts; they are the same format.

### Generate the Dockerfile

**Prompt:**

```txt
Write a Dockerfile for the Node.js Express app in the app/ directory. Requirements:
- Base image: node:22-alpine (pin the major version).
- WORKDIR /app.
- Copy package*.json first and run npm install before copying the rest of the source, so the dependency install is a separate cached layer.
- Copy the remaining source files.
- EXPOSE 3000.
- CMD ["npm", "start"].
Place the file at app/Dockerfile.
```

### Understanding the Dockerfile

| Instruction | Purpose |
|---|---|
| `FROM node:22-alpine` | Minimal Node.js 22 base image; Alpine reduces image size significantly |
| `WORKDIR /app` | Sets the working directory for all subsequent instructions |
| `COPY package*.json ./` | Copies only the dependency manifest before any source code |
| `RUN npm install` | Installs dependencies as a separate, cacheable layer |
| `COPY . .` | Copies application source after dependencies are installed |
| `EXPOSE 3000` | Documents the port the container listens on; does not publish it to the host |
| `CMD ["npm", "start"]` | The command run when a container starts from this image |

The ordering of `COPY package*.json` → `RUN npm install` → `COPY . .` is the most important concept in this section. Container images are built in layers. When you rebuild an image, Docker (and Podman) reuse cached layers up to the first change. If source files change but `package.json` does not, the `npm install` layer is reused and the rebuild takes seconds instead of minutes. If source and dependencies were copied together in one step, every rebuild would re-run `npm install`.

`EXPOSE` is documentation only. It does not publish port 3000 on the host. Publishing happens at container run time, via the port mapping in the Ansible role in Part 5.

**What to observe:** The Dockerfile Bob generates should follow the layer-ordering pattern above. If it copies all source files before running `npm install`, ask Bob to fix the ordering and explain why.

---

## Part 5: Deploy with Ansible

**Objective:** The containerized API is running on Podman, deployed and managed by Ansible. `curl http://localhost:3000/health` returns `{"status":"ok"}`.

**Mode: ⚡ Ansible Developer**

Switch Bob back to `⚡ Ansible Developer` mode. The application and container work is done; the remaining task is deployment automation.

**To switch modes:** Open the mode selector in Bob and choose **⚡ Ansible Developer**.

Following the same roles pattern from Part 2, you will create a `deploy_app` role and a thin `playbooks/deploy.yml` that calls it. The `containers.podman` collection installed in Part 2 provides modules that manage container state declaratively — you describe what you want (an image built, a container running) and Ansible determines what actions are needed to get there.

### About the app_src_path Variable

The `deploy_app` role needs to know where the `app/` directory is so it can find the Dockerfile to build from. Because playbooks live in `playbooks/`, the Ansible magic variable `{{ playbook_dir }}` resolves to `Ansible Lab/playbooks`, not the project root. The role's default will use `{{ playbook_dir | dirname }}/app` — the `dirname` filter strips the last path segment, giving `Ansible Lab/`, and then `/app` is appended. This is the one Jinja2 filter used in the lab and it is worth noting.

### Step 1 — Generate the deploy_app Role

**Prompt:**

```txt
Using Ansible Developer best practices, create an Ansible role named deploy_app under roles/deploy_app/. Requirements:
- defaults/main.yml defines: app_image_name: my-api, app_image_tag: latest, app_src_path: "{{ playbook_dir | dirname }}/app", container_name: my-api, host_port: 3000, container_port: 3000.
- tasks/main.yml uses containers.podman.podman_image to build the image from the app_src_path directory with name "{{ app_image_name }}" and tag "{{ app_image_tag }}", state: present.
- tasks/main.yml uses containers.podman.podman_container with name "{{ container_name }}", image "{{ app_image_name }}:{{ app_image_tag }}", state: started, ports: ["{{ host_port }}:{{ container_port }}"], recreate: true.
- No become on any task — the container runs rootless as the current user.
Add a comment above each task explaining what it does and why.
```

**Expected result:**

```
roles/deploy_app/
├── defaults/
│ └── main.yml
└── tasks/
 └── main.yml
```

**What to observe:** Every configurable value is a variable in `defaults/main.yml`, not a hardcoded string in the task file. To deploy a different image name or on a different port, the defaults are overridden — the role itself is not modified. This is what makes roles reusable.

Note `recreate: true` on the `podman_container` task. This ensures the lab works reliably on repeated runs by re-creating the container if it already exists. The tradeoff is that the container task will always report `changed`, even when nothing in the application has actually changed. A production pipeline would address this by tagging images with a version or commit hash rather than `latest` — but `recreate: true` keeps the lab predictable.

### Step 2 — Generate the deploy.yml Playbook

**Prompt:**

```txt
Create a playbook at playbooks/deploy.yml. It should target the local group, list the deploy_app role under roles:, and contain nothing else.
```

### Step 3 — Run the Deployment

```txt
Run ansible-playbook playbooks/deploy.yml from the Ansible Lab directory and confirm the container starts successfully.
```

**What to observe:**

1. The `podman_image` task builds the image from `app/Dockerfile`. On first run, the base image is pulled from the internet — this may take a minute.
2. The `podman_container` task starts the container and maps port 3000.

Confirm the container is running:

```bash
podman ps
```

The output should show `my-api` with `0.0.0.0:3000->3000/tcp` in the ports column.

Test the API:

```bash
curl http://localhost:3000/health
```

Expected response:

```json
{"status":"ok"}
```

---

## Verification

All commands are run from `Ansible Lab/`.

| Check | Command | Expected Output |
|---|---|---|
| Ansible installed | `ansible --version` | Version string; `config file` points to `ansible.cfg` |
| Node.js installed | `node --version` | Version string |
| Podman installed | `podman --version` | Version string |
| Collection installed | `ansible-galaxy collection list containers.podman` | Collection listed with version |
| App files present | `ls app/` | `index.js`, `package.json`, `Dockerfile`, `.gitignore` |
| Image built | `podman images` | `my-api` image listed |
| Container running | `podman ps` | `my-api` with `0.0.0.0:3000->3000/tcp` |
| API responding | `curl http://localhost:3000/health` | `{"status":"ok"}` |

If the API does not respond, check the container logs:

```bash
podman logs my-api
```

### What You Have Built

By completing this lab, you have used IBM Bob to generate an entire provision-to-deploy pipeline through natural-language prompts. The result is a containerized Node.js API deployed to Podman via three modular Ansible roles — `nodejs`, `podman`, and `deploy_app` — composed by two thin playbooks. Every dependency was installed declaratively. The same playbooks can be re-run safely against any RHEL VM to reproduce the same result.

---

## Teardown

To stop and remove the running container:

```bash
podman stop my-api
podman rm my-api
podman rmi my-api:latest
```

To also remove installed Node.js modules:

```bash
rm -rf app/node_modules
```

### Stretch Exercise

Ask Bob to generate a `playbooks/teardown.yml` that removes the container using `containers.podman.podman_container` with `state: absent` and removes the image using `containers.podman.podman_image` with `state: absent`. This is a good self-directed exercise that reinforces declarative state management — absence is a state, not just the default.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `couldn't resolve module/action 'containers.podman.podman_image'` | Collection installed as root, invisible to current user | Re-run the Part 2 collection task with `become: false`; verify with `ansible-galaxy collection list` |
| `the role 'nodejs' was not found` (or `podman`, `deploy_app`) | Running `ansible-playbook` from outside the project root; `ansible.cfg` not loaded | `cd` to `Ansible Lab/`; confirm with `ansible --version` — `config file` must not be `None` |
| `port is already allocated` or `address already in use` | The Part 3 dev server is still running, or a container from a previous run exists | Ctrl+C the dev server; run `podman ps -a`, then `podman stop my-api && podman rm my-api` |
| `No package ansible-core available` | Wrong repository or package name | Confirm `dnf repolist` includes AppStream; try `sudo dnf install -y ansible-core` |
| `curl: (7) Failed to connect` | Container exited on startup | `podman logs my-api` to see the error |
| Second playbook run still shows `changed` on the collection task | Missing `creates:` guard on the collection install task | Ask Bob to add `creates: "{{ ansible_env.HOME }}/.ansible/collections/ansible_collections/containers/podman"` to that task |

**General diagnostics:**

- Add `-v` to any `ansible-playbook` command for more detail.
- `ansible --version` is the fastest way to confirm you are in the right directory — the `config file` line tells you exactly which `ansible.cfg` is in use.
