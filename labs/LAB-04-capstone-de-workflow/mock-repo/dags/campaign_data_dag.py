"""Campaign data DAG — marketing attribution.

Pulls campaign metrics from S3 and external API, aggregates,
writes to Snowflake.

Tables written:
- ANALYTICS.RAW.CAMPAIGN_METRICS
"""
from __future__ import annotations

from datetime import datetime, timedelta

from airflow import DAG
from airflow.models import Variable
from airflow.operators.empty import EmptyOperator

DAG_ID = "campaign_data_ingestion"
SNOWFLAKE_STAGE = Variable.get(
    "snowflake_s3_stage",
    default_var="@ANALYTICS.RAW.S3_STAGE_DEV",
)


with DAG(
    dag_id=DAG_ID,
    description="Pull campaign metrics for marketing attribution.",
    schedule="0 5 * * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["analytics", "marketing", "raw"],
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
