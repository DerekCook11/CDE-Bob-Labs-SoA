"""SQLite connection and schema initialization."""

import sqlite3
from flask import g

from config import DATABASE_PATH


def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DATABASE_PATH)
        g.db.row_factory = sqlite3.Row
    return g.db


def close_db(_error=None):
    database = g.pop("db", None)
    if database is not None:
        database.close()


def initialize_database(app):
    with app.app_context():
        database = get_db()
        database.execute(
            """
            CREATE TABLE IF NOT EXISTS tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT NOT NULL DEFAULT '',
                completed INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            """
        )
        count = database.execute("SELECT COUNT(*) FROM tasks").fetchone()[0]
        if count == 0:
            database.executemany(
                "INSERT INTO tasks (title, description) VALUES (?, ?)",
                [
                    ("Review Bob Findings", "Inspect the initial security findings."),
                    ("Create remediation plan", "Prioritize fixes by severity and impact."),
                    ("Verify secure version", "Run the before-and-after checks."),
                ],
            )
        database.commit()

