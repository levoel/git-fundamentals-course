# Добавление в `dags/README.md` для user_events_ingestion DAG

Вставь следующий блок в `dags/README.md` (после `## analytics_main_etl_dag`):

```markdown
## user_events_ingestion

**Purpose**: Daily ingestion of user behavior events from S3 to Snowflake.

**Schedule**: Daily at 04:00 UTC (`0 4 * * *`).

**Source**: `s3://company-events-bucket/user_events/year={Y}/month={M}/day={D}/*.parquet`

**Target**: `ANALYTICS.RAW.USER_EVENTS`

**Owner**: data-engineering@acme-corp.com

**Idempotency**: Re-runs DELETE current partition before COPY INTO. Safe to retry.

**Tables written**:
- `ANALYTICS.RAW.USER_EVENTS`

**Ticket**: DE-1234
```
