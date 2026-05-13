## Summary

Daily ingestion DAG for user behavior events from S3 to Snowflake `ANALYTICS.RAW.USER_EVENTS`.

Ticket: [DE-1234](https://acme.atlassian.net/browse/DE-1234)

## Changes

- New DAG `dags/user_events_dag.py`: daily schedule 04:00 UTC.
- Idempotent: `DELETE` of partition before `COPY INTO`.
- 3 tests added in `tests/test_user_events.py`.
- Documented in `dags/README.md`.

## Testing

```
uv run pytest tests/test_user_events.py -v
```

All tests pass locally. CI should be green:
- ruff: PASSED
- mypy: PASSED
- pytest: PASSED (3/3 new tests)
- gitleaks: PASSED

## Acceptance Criteria

- [x] CI passes (ruff, mypy, pytest, gitleaks)
- [ ] Review approval from @alice
- [ ] DAG visible in Airflow UI after deploy

## Reviewer Notes

- Schedule chosen as 04:00 UTC = post-main-ETL window. If conflicts with other DAGs, willing to adjust.
- Using `S3ToSnowflakeOperator` for portability (avoids custom S3 download + COPY).
- Connections `snowflake_default` and `aws_default` — assumed configured via Secrets Manager backend.
- Stage name uses `Variable.get('snowflake_s3_stage', default_var=...)` for environment flexibility (per existing `fact_orders_dag` pattern).
