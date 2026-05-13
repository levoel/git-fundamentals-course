"""S3 utilities for DAGs."""
from __future__ import annotations


def build_s3_partition_key(
    prefix: str,
    year: str,
    month: str,
    day: str,
) -> str:
    """Build S3 key for date-partitioned data.

    Args:
        prefix: dataset prefix (e.g., 'orders/').
        year: 4-digit year string.
        month: 2-digit month string.
        day: 2-digit day string.

    Returns:
        S3 key path.
    """
    return f"{prefix}year={year}/month={month}/day={day}/"
