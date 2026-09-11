"""Intentionally vulnerable training configuration.

These values are fake and exist only so IBM Bob can identify and remediate
common secret-management and runtime-configuration findings.
"""

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

# VULNERABILITY: hardcoded secrets and credentials.
SECRET_KEY = "training-secret-key-please-change"
ADMIN_PASSWORD = "BobLabAdmin123!"
API_KEY = "sk_training_51ABCDEF_not_a_real_key"

# SQLite keeps this lab self-contained. No database server is required.
DATABASE_PATH = os.getenv("DATABASE_PATH", str(BASE_DIR / "tasks.db"))

# VULNERABILITY: permissive CORS and debug mode.
CORS_ORIGINS = "*"
DEBUG = True

HOST = os.getenv("APP_HOST", "0.0.0.0")
PORT = int(os.getenv("APP_PORT", "5000"))

