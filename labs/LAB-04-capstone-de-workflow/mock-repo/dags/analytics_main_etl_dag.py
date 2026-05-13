"""Analytics main ETL DAG.

Main ETL pipeline — joins raw tables, builds marts.

Tables written:
- ANALYTICS.MARTS.CUSTOMERS
- ANALYTICS.MARTS.ORDERS_DAILY
- ANALYTICS.MARTS.REVENUE_DAILY
"""
from __future__ import annotations

from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.empty import EmptyOperator

DAG_ID = "analytics_main_etl"


with DAG(
    dag_id=DAG_ID,
    description="Main analytics ETL: marts.",
    schedule="0 6 * * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["analytics", "marts"],
    default_args={
        "owner": "analytics-engineering",
        "retries": 2,
        "retry_delay": timedelta(minutes=10),
    },
) as dag:
    # Placeholder для actual implementation
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end")

    start >> end
