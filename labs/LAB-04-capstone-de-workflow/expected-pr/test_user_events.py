"""Tests for user_events_dag."""
from __future__ import annotations

from airflow.models.dagbag import DagBag


def test_dag_imports_without_error() -> None:
    """DAG file should be importable — smoke test."""
    dag_bag = DagBag(include_examples=False)
    assert "user_events_ingestion" in dag_bag.dag_ids
    assert dag_bag.dags["user_events_ingestion"] is not None


def test_dag_has_expected_tasks() -> None:
    """DAG should have two tasks: delete + copy."""
    dag_bag = DagBag(include_examples=False)
    dag = dag_bag.dags["user_events_ingestion"]
    task_ids = sorted(t.task_id for t in dag.tasks)
    assert task_ids == ["copy_into_snowflake", "delete_existing_partition"]


def test_dag_schedule_is_daily_04() -> None:
    """Schedule must be 04:00 daily UTC."""
    dag_bag = DagBag(include_examples=False)
    dag = dag_bag.dags["user_events_ingestion"]
    assert dag.schedule_interval == "0 4 * * *"
