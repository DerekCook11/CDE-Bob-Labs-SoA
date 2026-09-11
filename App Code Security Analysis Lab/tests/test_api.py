"""Functional regression tests that must pass before and after remediation."""

import importlib
import os
import sys
import tempfile
import unittest
from pathlib import Path


TARGET = os.getenv("LAB_TARGET", "vulnerable-app")
ROOT = Path(__file__).resolve().parents[1]
BACKEND = ROOT / TARGET / "backend"
TEMP_DIR = tempfile.TemporaryDirectory()
os.environ["DATABASE_PATH"] = str(Path(TEMP_DIR.name) / "test_tasks.db")
sys.path.insert(0, str(BACKEND))

app_module = importlib.import_module("app")


class ApiFunctionalityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        app_module.app.config.update(TESTING=True)
        cls.client = app_module.app.test_client()

    def test_health(self):
        response = self.client.get("/api/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["status"], "healthy")

    def test_create_update_search_delete(self):
        created = self.client.post(
            "/api/tasks",
            json={"title": "Functional test", "description": "Created by unittest"},
        )
        self.assertEqual(created.status_code, 201)
        task = created.get_json()

        listed = self.client.get("/api/tasks")
        self.assertEqual(listed.status_code, 200)
        self.assertTrue(any(item["id"] == task["id"] for item in listed.get_json()))

        updated = self.client.put(
            f"/api/tasks/{task['id']}",
            json={**task, "completed": True},
        )
        self.assertEqual(updated.status_code, 200)
        self.assertTrue(updated.get_json()["completed"])

        searched = self.client.get("/api/tasks/search?q=Functional")
        self.assertEqual(searched.status_code, 200)
        self.assertTrue(any(item["id"] == task["id"] for item in searched.get_json()))

        deleted = self.client.delete(f"/api/tasks/{task['id']}")
        self.assertEqual(deleted.status_code, 200)


if __name__ == "__main__":
    unittest.main()

