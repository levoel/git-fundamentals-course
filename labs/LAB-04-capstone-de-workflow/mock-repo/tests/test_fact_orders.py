"""Tests for fact_orders_dag."""
from __future__ import annotations

import pytest
from airflow.models.dagbag import DagBag


def test_dag_imports_without_error() -> None:
    """DAG file should be importable — smoke test."""
    dag_bag = DagBag(include_examples=False)
    assert "fact_orders_ingestion" in dag_bag.dag_ids
    assert dag_bag.dags["fact_orders_ingestion"] is not None


def test_dag_has_expected_tasks() -> None:
    """DAG should have two tasks: delete + copy."""
    dag_bag = DagBag(include_examples=False)
    dag = dag_bag.dags["fact_orders_ingestion"]
    task_ids = sorted(t.task_id for t in dag.tasks)
    assert task_ids == ["copy_into_snowflake", "delete_existing_partition"]


def test_dag_schedule_is_daily_03() -> None:
    """Schedule must be 03:00 daily UTC."""
    dag_bag = DagBag(include_examples=False)
    dag = dag_bag.dags["fact_orders_ingestion"]
    assert dag.schedule_interval == "0 3 * * *"
