"""Pytest configuration and fixtures."""
from __future__ import annotations

import os
import sys
from pathlib import Path

# Make dags/ importable
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

# Set Airflow home to avoid polluting user's home
os.environ["AIRFLOW_HOME"] = str(PROJECT_ROOT / ".airflow_home_test")
os.environ["AIRFLOW__CORE__LOAD_EXAMPLES"] = "False"
os.environ["AIRFLOW__CORE__DAGS_FOLDER"] = str(PROJECT_ROOT / "dags")
