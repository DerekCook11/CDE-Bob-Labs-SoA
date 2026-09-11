# Reference Solutions

This file contains one valid implementation of every file Bob is expected to generate during the lab. Student output may differ in style or structure and still be correct — Bob's output varies between sessions.

Use these as a reference when student output is clearly broken or missing a critical element, not as a transcription target.

---

## ansible.cfg

```ini
[defaults]
inventory = inventory.ini
roles_path = ./roles
stdout_callback = yaml
interpreter_python = auto_silent
```

---

## inventory.ini

```ini
[local]
localhost ansible_connection=local
```

---

## roles/nodejs/defaults/main.yml

```yaml
---
nodejs_packages:
 - nodejs
 - npm
```

---

## roles/nodejs/tasks/main.yml

```yaml
---
# Install Node.js and npm from the system package manager.
# Using ansible.builtin.dnf with become: true for privilege escalation.
# The package list is sourced from defaults/main.yml so it can be overridden.
- name: Install Node.js and npm
 ansible.builtin.dnf:
 name: "{{ nodejs_packages }}"
 state: present
 become: true

# Verify Node.js installation and capture the version.
# changed_when: false tells Ansible this task never modifies state,
# which keeps the PLAY RECAP accurate.
- name: Get Node.js version
 ansible.builtin.command: node --version
 register: node_version
 changed_when: false

# Verify npm installation and capture the version.
- name: Get npm version
 ansible.builtin.command: npm --version
 register: npm_version
 changed_when: false

# Display the installed versions so the student can confirm the install worked.
- name: Print Node.js and npm versions
 ansible.builtin.debug:
 msg:
 - "Node.js: {{ node_version.stdout }}"
 - "npm: {{ npm_version.stdout }}"
```

---

## roles/podman/defaults/main.yml

```yaml
---
podman_package: podman
containers_podman_collection: containers.podman
containers_podman_collection_path: "{{ ansible_env.HOME }}/.ansible/collections/ansible_collections/containers/podman"
```

---

## roles/podman/tasks/main.yml

```yaml
---
# Install Podman from the system package manager.
# become: true is required for dnf; it is scoped to this task only,
# not the entire play, to avoid running container tasks as root.
- name: Install Podman
 ansible.builtin.dnf:
 name: "{{ podman_package }}"
 state: present
 become: true

# Verify the Podman installation.
# changed_when: false marks this as a read-only task.
- name: Get Podman version
 ansible.builtin.command: podman --version
 register: podman_version
 changed_when: false

- name: Print Podman version
 ansible.builtin.debug:
 msg: "Podman: {{ podman_version.stdout }}"

# Install the containers.podman Ansible collection.
# become: false is critical — if this runs as root, the collection installs
# into /root/.ansible/collections and is invisible to the current user's
# ansible-playbook calls in Part 5.
# The creates: guard makes this task idempotent: it is skipped if the
# collection directory already exists, so the second run shows changed=0.
- name: Install containers.podman collection
 ansible.builtin.command: ansible-galaxy collection install containers.podman
 become: false
 args:
 creates: "{{ containers_podman_collection_path }}"
```

---

## playbooks/setup.yml

```yaml
---
- name: Provision the local VM
 hosts: local
 roles:
 - nodejs
 - podman
```

---

## app/index.js

```javascript
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/health', (req, res) => {
 res.json({ status: 'ok' });
});

app.listen(PORT, () => {
 console.log(`Server running on port ${PORT}`);
});
```

---

## app/package.json

```json
{
 "name": "my-api",
 "version": "1.0.0",
 "description": "Minimal Express health-check API",
 "main": "index.js",
 "scripts": {
 "start": "node index.js"
 },
 "dependencies": {
 "express": "^4.18.0"
 }
}
```

---

## app/.gitignore

```
node_modules/
```

---

## app/Dockerfile

```dockerfile
FROM node:22-alpine

WORKDIR /app

# Copy dependency manifest first so the npm install layer is cached
# separately from the application source. If only source files change,
# the npm install step is reused from cache on the next build.
COPY package*.json ./
RUN npm install

# Copy the rest of the application source
COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

---

## roles/deploy_app/defaults/main.yml

```yaml
---
app_image_name: my-api
app_image_tag: latest
# playbook_dir resolves to Ansible Lab/playbooks; dirname strips the last
# segment to get the project root, then /app is appended.
app_src_path: "{{ playbook_dir | dirname }}/app"
container_name: my-api
host_port: 3000
container_port: 3000
```

---

## roles/deploy_app/tasks/main.yml

```yaml
---
# Build the container image from the Dockerfile in app_src_path.
# state: present means "build if not already built."
# The image is tagged with app_image_name:app_image_tag.
- name: Build the application container image
 containers.podman.podman_image:
 name: "{{ app_image_name }}"
 tag: "{{ app_image_tag }}"
 path: "{{ app_src_path }}"
 state: present

# Run the container with the built image.
# state: started means "ensure the container is running."
# recreate: true re-creates the container on each run, which keeps the lab
# reliable across repeated runs. In production, use versioned image tags
# rather than recreate to preserve strict idempotency.
# No become — rootless Podman runs as the current user.
- name: Run the application container
 containers.podman.podman_container:
 name: "{{ container_name }}"
 image: "{{ app_image_name }}:{{ app_image_tag }}"
 state: started
 ports:
 - "{{ host_port }}:{{ container_port }}"
 recreate: true
```

---

## playbooks/deploy.yml

```yaml
---
- name: Deploy the application container
 hosts: local
 roles:
 - deploy_app
```
