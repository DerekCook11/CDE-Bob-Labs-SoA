// The API host follows the browser host so the app works on a remote lab VM.
const API_ROOT = `http://${window.location.hostname}:5000/api`;
const taskList = document.querySelector('#task-list');
const taskCount = document.querySelector('#task-count');
const taskForm = document.querySelector('#task-form');
const searchInput = document.querySelector('#search');
const message = document.querySelector('#message');

let tasks = [];

function showMessage(text, isError = false) {
  message.textContent = text;
  message.style.color = isError ? '#ff8a82' : '#44d7d1';
}

async function api(path = '', options = {}) {
  const response = await fetch(`${API_ROOT}${path}`, {
    headers: { 'Content-Type': 'application/json', ...(options.headers || {}) },
    ...options,
  });
  const body = await response.json();
  if (!response.ok) throw new Error(body.details || body.error || 'Request failed');
  return body;
}

function renderTasks() {
  taskCount.textContent = `${tasks.length} ${tasks.length === 1 ? 'task' : 'tasks'}`;

  if (!tasks.length) {
    taskList.replaceChildren(document.querySelector('#empty-state').content.cloneNode(true));
    return;
  }

  // VULNERABILITY: API-controlled text is inserted as HTML without encoding.
  taskList.innerHTML = tasks.map((task) => `
    <article class="task ${task.completed ? 'completed' : ''}">
      <input type="checkbox" ${task.completed ? 'checked' : ''}
             onchange="toggleTask(${task.id})" aria-label="Mark task complete">
      <div>
        <h3>${task.title}</h3>
        <p>${task.description || 'No description'}</p>
      </div>
      <div class="task-actions">
        <button class="danger" onclick="deleteTask(${task.id})">Delete</button>
      </div>
    </article>
  `).join('');
}

async function loadTasks() {
  try {
    tasks = await api('/tasks');
    renderTasks();
    showMessage('');
  } catch (error) {
    showMessage(`Unable to load tasks: ${error.message}`, true);
  }
}

taskForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const payload = {
    title: document.querySelector('#title').value,
    description: document.querySelector('#description').value,
  };

  try {
    await api('/tasks', { method: 'POST', body: JSON.stringify(payload) });
    taskForm.reset();
    showMessage('Task added.');
    await loadTasks();
  } catch (error) {
    showMessage(error.message, true);
  }
});

async function toggleTask(taskId) {
  const task = tasks.find((item) => item.id === taskId);
  if (!task) return;
  try {
    await api(`/tasks/${taskId}`, {
      method: 'PUT',
      body: JSON.stringify({ ...task, completed: !task.completed }),
    });
    await loadTasks();
  } catch (error) {
    showMessage(error.message, true);
  }
}

async function deleteTask(taskId) {
  try {
    await api(`/tasks/${taskId}`, { method: 'DELETE' });
    showMessage('Task deleted.');
    await loadTasks();
  } catch (error) {
    showMessage(error.message, true);
  }
}

async function searchTasks() {
  const query = searchInput.value;
  try {
    tasks = await api(`/tasks/search?q=${encodeURIComponent(query)}`);
    renderTasks();
    showMessage(query ? `Showing results for “${query}”.` : 'Showing all tasks.');
  } catch (error) {
    showMessage(error.message, true);
  }
}

document.querySelector('#search-button').addEventListener('click', searchTasks);
document.querySelector('#clear-button').addEventListener('click', () => {
  searchInput.value = '';
  loadTasks();
});
searchInput.addEventListener('keydown', (event) => {
  if (event.key === 'Enter') searchTasks();
});

loadTasks();

