"""Secret retrieval helpers.

In production, fetches from AWS Secrets Manager via Airflow secrets backend.
"""
from __future__ import annotations

from airflow.models import Variable


def get_secret(name: str, default: str | None = None) -> str:
    """Get a secret value from Airflow Variables (backed by Secrets Manager).

    Args:
        name: secret name.
        default: fallback if not found.

    Returns:
        secret value.

    Raises:
        KeyError: if not found and no default.
    """
    if default is not None:
        return Variable.get(name, default_var=default)
    return Variable.get(name)
