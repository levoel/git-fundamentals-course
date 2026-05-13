"""Compute customer retention cohorts.

Used by the Marketing retention dashboard. Returns a dataframe with
cohort retention rates (month-over-month) for the last 12 months.
"""

from __future__ import annotations

import pandas as pd
from sqlalchemy.engine import Engine


def compute_retention(engine: Engine, months: int = 12) -> pd.DataFrame:
    """Compute monthly retention cohorts.

    Args:
        engine: SQLAlchemy engine pointing at the warehouse.
        months: Number of months to compute cohorts for. Default 12.

    Returns:
        DataFrame with columns: cohort_month, period_months, retention_rate.
    """
    query = f"""
    WITH cohorts AS (
        SELECT
            DATE_TRUNC('month', signup_date) AS cohort_month,
            customer_id
        FROM dim_customers
        WHERE signup_date >= CURRENT_DATE - INTERVAL '{months} months'
    ),
    activity AS (
        SELECT
            customer_id,
            DATE_TRUNC('month', order_date) AS activity_month
        FROM fct_orders
        WHERE order_date >= CURRENT_DATE - INTERVAL '{months} months'
    ),
    cohort_activity AS (
        SELECT
            c.cohort_month,
            a.activity_month,
            COUNT(DISTINCT c.customer_id) AS active_users
        FROM cohorts c
        JOIN activity a ON c.customer_id = a.customer_id
        GROUP BY c.cohort_month, a.activity_month
    )
    SELECT
        cohort_month,
        DATEDIFF('month', cohort_month, activity_month) AS period_months,
        active_users
    FROM cohort_activity
    ORDER BY cohort_month, period_months
    """

    df = pd.read_sql(query, engine)

    # Compute retention rate per cohort
    base = df[df["period_months"] == 0].set_index("cohort_month")["active_users"]
    df["base"] = df["cohort_month"].map(base)
    df["retention_rate"] = df["active_users"] / df["base"]

    return df[["cohort_month", "period_months", "retention_rate"]]


def save_to_csv(df: pd.DataFrame, path: str) -> None:
    """Save retention dataframe to CSV."""
    df.to_csv(path, index=False)


if __name__ == "__main__":
    from sqlalchemy import create_engine

    eng = create_engine("postgresql://user:password@localhost:5432/warehouse")
    result = compute_retention(eng, months=12)
    save_to_csv(result, "/tmp/retention.csv")
    print(f"Saved {len(result)} rows to /tmp/retention.csv")
