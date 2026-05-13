"""Snowflake loading helpers."""
from __future__ import annotations


def build_copy_into_sql(table: str, stage: str, file_format: str) -> str:
    """Build COPY INTO SQL for Snowflake.

    Args:
        table: target table name.
        stage: Snowflake stage reference.
        file_format: file format spec.

    Returns:
        SQL string ready to execute.
    """
    return (
        f"COPY INTO {table} "
        f"FROM {stage} "
        f"FILE_FORMAT = {file_format} "
        "ON_ERROR = 'CONTINUE';"
    )
