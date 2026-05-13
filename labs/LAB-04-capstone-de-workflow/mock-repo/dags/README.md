# DAGs

Документация по существующим Airflow DAG-ам.

## fact_orders_dag

**Purpose**: Daily ingestion of orders from S3 to Snowflake `ANALYTICS.RAW.ORDERS`.

**Schedule**: `0 3 * * *` (03:00 UTC).

**Source**: `s3://company-orders-bucket/orders/year={Y}/month={M}/day={D}/*.parquet`

**Target**: `ANALYTICS.RAW.ORDERS`

**Owner**: data-engineering@acme-corp.com

**Idempotency**: DELETE partition before COPY INTO. Safe to retry.

## campaign_data_dag

**Purpose**: Marketing attribution data from S3 + API to Snowflake.

**Schedule**: `0 5 * * *` (05:00 UTC).

**Owner**: analytics-engineering@acme-corp.com

## analytics_main_etl_dag

**Purpose**: Main analytics ETL — joins, aggregations, marts.

**Schedule**: `0 6 * * *` (06:00 UTC, после raw ingestion).

**Owner**: analytics-engineering@acme-corp.com

**Tables written**:
- `ANALYTICS.MARTS.CUSTOMERS`
- `ANALYTICS.MARTS.ORDERS_DAILY`
- `ANALYTICS.MARTS.REVENUE_DAILY`

---

<!-- Junior: добавь сюда секцию для user_events_ingestion DAG в Step 4.4 -->
