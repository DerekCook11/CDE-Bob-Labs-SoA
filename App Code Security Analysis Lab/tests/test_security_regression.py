"""Security regression tests expected to fail before fixes and pass afterward."""

import importlib
import os
import sys
import tempfile
import unittest
from pathlib import Path


TARGET = os.getenv("LAB_TARGET", "secure-app")
ROOT = Path(__file__).resolve().parents[1]
BACKEND = ROOT / TARGET / "backend"
TEMP_DIR = tempfile.TemporaryDirectory()
os.environ["DATABASE_PATH"] = str(Path(TEMP_DIR.name) / "security_tasks.db")
os.environ.setdefault("SECRET_KEY", "test-secret-not-for-production")
os.environ.setdefault("ADMIN_PASSWORD", "test-admin-password")
os.environ.setdefault("API_KEY", "test-api-key")
os.environ.setdefault("ALLOWED_ORIGINS", "http://localhost:8080")
sys.path.insert(0, str(BACKEND))

app_module = importlib.import_module("app")


class SecurityRegressionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        app_module.app.config.update(TESTING=True)
        cls.client = app_module.app.test_client()

    def test_blank_title_is_rejected(self):
        response = self.client.post(
            "/api/tasks", json={"title": "   ", "description": "invalid"}
        )
        self.assertEqual(response.status_code, 400)

    def test_non_boolean_completed_is_rejected(self):
        response = self.client.put(
            "/api/tasks/1",
            json={"title": "Task", "description": "Test", "completed": "yes"},
        )
        self.assertEqual(response.status_code, 400)

    def test_sql_injection_does_not_bypass_search(self):
        response = self.client.get("/api/tasks/search", query_string={"q": "' OR 1=1 --"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), [])

    def test_config_endpoint_does_not_expose_secrets(self):
        response = self.client.get("/api/admin/config")
        body = response.get_data(as_text=True)
        configured_values = [
            getattr(app_module.config, "API_KEY", ""),
            getattr(app_module.config, "ADMIN_PASSWORD", ""),
            getattr(app_module.config, "SECRET_KEY", ""),
        ]
        for value in configured_values:
            if value:
                self.assertNotIn(value, body)


if __name__ == "__main__":
    unittest.main()
