"""User events ingestion DAG.

Loads user behavior events from S3 (Parquet, partitioned by date) into
Snowflake table ANALYTICS.RAW.USER_EVENTS.

Schedule: daily at 04:00 UTC (after main ETL).
Idempotent: re-runs delete existing partition before re-insert.

Tables written:
- ANALYTICS.RAW.USER_EVENTS (partitioned by event_date)

Ticket: DE-1234.
"""
from __future__ import annotations

from datetime import datetime, timedelta

from airflow import DAG
from airflow.models import Variable
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator
from airflow.providers.snowflake.transfers.s3_to_snowflake import S3ToSnowflakeOperator

DAG_ID = "user_events_ingestion"
S3_BUCKET = "company-events-bucket"
S3_KEY_PREFIX = "user_events/year={ds_y}/month={ds_m}/day={ds_d}/"
SNOWFLAKE_TABLE = "ANALYTICS.RAW.USER_EVENTS"
SNOWFLAKE_STAGE = Variable.get(
    "snowflake_s3_stage",
    default_var="@ANALYTICS.RAW.S3_STAGE_DEV",
)


with DAG(
    dag_id=DAG_ID,
    description="Load user events from S3 to Snowflake daily.",
    schedule="0 4 * * *",  # 04:00 UTC
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["analytics", "user-events", "marketing"],
    default_args={
        "owner": "data-engineering",
        "retries": 2,
        "retry_delay": timedelta(minutes=5),
    },
) as dag:

    delete_existing = SnowflakeOperator(
        task_id="delete_existing_partition",
        snowflake_conn_id="snowflake_default",
        sql=(
            f"DELETE FROM {SNOWFLAKE_TABLE} "
            "WHERE event_date = TO_DATE('{{ ds }}', 'YYYY-MM-DD');"
        ),
    )

    load_to_snowflake = S3ToSnowflakeOperator(
        task_id="copy_into_snowflake",
        s3_keys=[
            S3_KEY_PREFIX.format(
                ds_y="{{ macros.ds_format(ds, '%Y-%m-%d', '%Y') }}",
                ds_m="{{ macros.ds_format(ds, '%Y-%m-%d', '%m') }}",
                ds_d="{{ macros.ds_format(ds, '%Y-%m-%d', '%d') }}",
            )
        ],
        table=SNOWFLAKE_TABLE,
        schema="RAW",
        stage=SNOWFLAKE_STAGE,
        file_format="(TYPE = PARQUET)",
        snowflake_conn_id="snowflake_default",
        aws_conn_id="aws_default",
    )

    delete_existing >> load_to_snowflake
