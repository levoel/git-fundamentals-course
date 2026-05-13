# Симуляция Code Review от @alice

5 comments разных типов. Junior должен правильно классифицировать каждый и react соответственно.

---

## Comment 1: BLOCKER

**File**: `dags/user_events_dag.py`
**Line**: ~23

```python
SNOWFLAKE_STAGE = "@ANALYTICS.RAW.S3_STAGE"
```

> This is hardcoded to a specific environment. Stage name should differ between **dev** / **staging** / **prod**. Use `Variable.get()` or pull from connection extras. See how `fact_orders_dag.py` does it.

**Type**: Blocker (must fix).

**Expected reaction**:
1. Look at `fact_orders_dag.py` for pattern.
2. Apply same: `SNOWFLAKE_STAGE = Variable.get("snowflake_s3_stage", default_var="@ANALYTICS.RAW.S3_STAGE_DEV")`.
3. Add `from airflow.models import Variable` import.
4. Commit: `fix(user_events_dag): use Variable.get() for stage name`.
5. Push.
6. Response in PR: `Good catch — switched to Variable.get() in <sha>. Tested by setting AIRFLOW_VAR_SNOWFLAKE_S3_STAGE override locally. Resolves issue.`

---

## Comment 2: SUGGESTION

**File**: `dags/user_events_dag.py`
**Line**: ~48 (default_args)

```python
"retry_delay": 300,  # 5 minutes
```

> Suggestion: use `timedelta(minutes=5)` for clarity. Bare ints work but team convention is timedelta. See default_args in other DAGs.

**Type**: Suggestion (recommended).

**Expected reaction**:
1. Apply change: `"retry_delay": timedelta(minutes=5)`.
2. Ensure `from datetime import timedelta` imported.
3. Commit: `style(user_events_dag): use timedelta for retry_delay`.
4. Push.
5. Response: `Agreed, switched to timedelta in <sha> — clearer.`

---

## Comment 3: NIT

**File**: `dags/user_events_dag.py`
**Line**: 1 (docstring)

> nit: docstring is good. Maybe add a `Tables written` section listing what tables get written? Match the style of `analytics_main_etl_dag.py`.

**Type**: Nit (minor, optional).

**Expected reaction**:
1. Quick fix (30 sec): add `Tables written:` section to docstring listing `ANALYTICS.RAW.USER_EVENTS`.
2. Commit: `docs(user_events_dag): add tables written to docstring per review`.
3. Response: `Done in <sha> — added section per analytics_main_etl_dag pattern.`

---

## Comment 4: QUESTION

**File**: `dags/user_events_dag.py`
**Line**: ~last line (`delete_existing >> load_to_snowflake`)

> Why `>>` instead of using `chain()`? Either works, just curious about your choice.

**Type**: Question (no code change needed).

**Expected reaction**:
1. **No code change**.
2. Response with reasoning:
```
For 2-task DAG `>>` reads cleaner — feels like reading "do A then B".
`chain()` is great for 3+ tasks where readability suffers. I'd switch to `chain()`
if we add a third task downstream.
```
3. Resolve conversation if Alice agrees.

---

## Comment 5: PRAISE

**File**: `dags/user_events_dag.py`
**Line**: ~35 (delete_existing operator)

```python
delete_existing = SnowflakeOperator(
    task_id="delete_existing_partition",
    ...
)
```

> Nice idempotency design — DELETE-then-INSERT pattern. Some teams forget this and end up with duplicates on retry.

**Type**: Praise.

**Expected reaction**:
1. **No code change**.
2. Short thanks:
```
Thanks! Definitely a footgun, learned from fact_orders_dag.
```

---

## После всех comments

После addressing всех comments + push:

1. **Re-request review** через GitHub UI (или wait for Alice automatic re-review).
2. Wait CI зелёный (новые commits).
3. Alice approves.
4. **Resolve все conversations** в PR (если не resolved автоматически).

## Final state

Перед переходом к Step 7 (rebase conflict simulation), PR должен:

- 4-5 additional commits после initial 3.
- 4 conversations resolved (blocker, suggestion, nit, question; praise auto-resolved).
- Зелёный CI.
- 1 approval от reviewer.

Готов к conflict resolution и merge.
