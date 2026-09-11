"""Intentionally vulnerable Flask API for the Security Analysis Lab.

WARNING: Training use only. Do not expose this application to the internet.
"""

from flask import Flask, jsonify, request
from flask_cors import CORS

import config
from database import close_db, get_db, initialize_database


app = Flask(__name__)
app.config["SECRET_KEY"] = config.SECRET_KEY

# VULNERABILITY: every origin is trusted.
CORS(app, origins=config.CORS_ORIGINS)
app.teardown_appcontext(close_db)
initialize_database(app)


def row_to_task(row):
    return {
        "id": row["id"],
        "title": row["title"],
        "description": row["description"],
        "completed": bool(row["completed"]),
        "created_at": row["created_at"],
    }


@app.get("/api/health")
def health():
    return jsonify({"status": "healthy", "version": "1.0-vulnerable"})


@app.get("/api/tasks")
def list_tasks():
    rows = get_db().execute(
        "SELECT * FROM tasks ORDER BY completed, id DESC"
    ).fetchall()
    return jsonify([row_to_task(row) for row in rows])


@app.post("/api/tasks")
def create_task():
    # VULNERABILITY: trusts the JSON body without type, presence, or length checks.
    payload = request.get_json()
    cursor = get_db().execute(
        "INSERT INTO tasks (title, description) VALUES (?, ?)",
        (payload.get("title", ""), payload.get("description", "")),
    )
    get_db().commit()
    row = get_db().execute(
        "SELECT * FROM tasks WHERE id = ?", (cursor.lastrowid,)
    ).fetchone()
    return jsonify(row_to_task(row)), 201


@app.put("/api/tasks/<int:task_id>")
def update_task(task_id):
    # VULNERABILITY: accepts arbitrary values without validation.
    payload = request.get_json()
    get_db().execute(
        """
        UPDATE tasks
           SET title = ?, description = ?, completed = ?
         WHERE id = ?
        """,
        (
            payload.get("title", ""),
            payload.get("description", ""),
            int(bool(payload.get("completed", False))),
            task_id,
        ),
    )
    get_db().commit()
    row = get_db().execute(
        "SELECT * FROM tasks WHERE id = ?", (task_id,)
    ).fetchone()
    if row is None:
        return jsonify({"error": "Task not found"}), 404
    return jsonify(row_to_task(row))


@app.delete("/api/tasks/<int:task_id>")
def delete_task(task_id):
    cursor = get_db().execute("DELETE FROM tasks WHERE id = ?", (task_id,))
    get_db().commit()
    if cursor.rowcount == 0:
        return jsonify({"error": "Task not found"}), 404
    return jsonify({"message": "Task deleted"})


@app.get("/api/tasks/search")
def search_tasks():
    query = request.args.get("q", "")

    # VULNERABILITY: user input is concatenated directly into SQL.
    sql = f"SELECT * FROM tasks WHERE title LIKE '%{query}%' ORDER BY id DESC"
    rows = get_db().execute(sql).fetchall()
    return jsonify([row_to_task(row) for row in rows])


@app.post("/api/admin/verify")
def verify_admin():
    payload = request.get_json()
    if payload.get("password") == config.ADMIN_PASSWORD:
        # VULNERABILITY: returns a sensitive key to the client.
        return jsonify({"authenticated": True, "api_key": config.API_KEY})
    return jsonify({"authenticated": False}), 401


@app.get("/api/admin/config")
def expose_config():
    # VULNERABILITY: unauthenticated endpoint exposes application secrets.
    return jsonify(
        {
            "secret_key": config.SECRET_KEY,
            "admin_password": config.ADMIN_PASSWORD,
            "api_key": config.API_KEY,
            "debug": config.DEBUG,
        }
    )


@app.errorhandler(Exception)
def handle_unexpected_error(error):
    # VULNERABILITY: internal exception details are returned to the caller.
    return (
        jsonify(
            {
                "error": "Unexpected server error",
                "details": str(error),
                "type": type(error).__name__,
            }
        ),
        500,
    )


if __name__ == "__main__":
    app.run(host=config.HOST, port=config.PORT, debug=config.DEBUG)

