#!/usr/bin/env bash
# setup.sh — создаёт тренировочный репозиторий для LAB-02.
#
# Идемпотентный: повторный запуск удалит и пересоздаст target-папку.
#
# Usage:
#   bash setup.sh <target-dir>
#
# Например:
#   bash setup.sh ~/de-projects/lab02-rebase

set -euo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: bash setup.sh <target-dir>"
  exit 1
fi

# Expand ~
TARGET="${TARGET/#\~/$HOME}"

REMOTE_DIR="${TARGET}-remote.git"

echo "Setting up LAB-02 in: $TARGET"
echo "Bare remote in:       $REMOTE_DIR"

# Clean
rm -rf "$TARGET" "$REMOTE_DIR"
mkdir -p "$TARGET"
cd "$TARGET"

# Force consistent commit metadata (so SHAs are reproducible-ish across runs)
export GIT_AUTHOR_NAME="Lab Author"
export GIT_AUTHOR_EMAIL="author@lab.local"
export GIT_COMMITTER_NAME="Lab Author"
export GIT_COMMITTER_EMAIL="author@lab.local"

git init -b main -q

# --- Base commit (shared ancestor) ---
mkdir -p src tests
cat > README.md <<'EOF'
# orders-etl

Tiny ETL pipeline for orders.
EOF

cat > src/etl.py <<'EOF'
"""ETL: extract, transform, load orders."""

import pandas as pd


def extract(path):
    return pd.read_csv(path)


def transform(df):
    df["total"] = df["qty"] * df["price"]
    return df
EOF

cat > src/db.py <<'EOF'
"""Database engine for warehouse loads."""

from sqlalchemy import create_engine

engine = create_engine("sqlite:///warehouse.db")
EOF

git add README.md src/etl.py src/db.py
GIT_COMMITTER_DATE="2026-01-10T10:00:00" git commit -q -m "chore: initial commit" --date "2026-01-10T10:00:00"

# --- Branch point: feature/etl-loader is created here ---
git branch feature/etl-loader

# ============================================================
# main branch: 4 progressive commits
# ============================================================

# main commit 1: feat: initial etl skeleton (expand etl.py)
cat > src/etl.py <<'EOF'
"""ETL: extract, transform, load orders."""

import pandas as pd


def extract(path):
    return pd.read_csv(path)


def transform(df):
    df["total"] = df["qty"] * df["price"]
    return df


def load_orders(df, table):
    """Stub for load step. To be implemented."""
    raise NotImplementedError
EOF
git add src/etl.py
GIT_COMMITTER_DATE="2026-01-11T10:00:00" git commit -q -m "feat: initial etl skeleton" --date "2026-01-11T10:00:00"

# main commit 2: docs: update README
cat > README.md <<'EOF'
# orders-etl

ETL pipeline for orders. Reads CSV, computes totals, loads into warehouse.

## Usage

```python
from src.etl import extract, transform, load_orders

df = extract("orders.csv")
df = transform(df)
load_orders(df, "fact_orders")
```
EOF
git add README.md
GIT_COMMITTER_DATE="2026-01-12T10:00:00" git commit -q -m "docs: update README" --date "2026-01-12T10:00:00"

# main commit 3: chore: bump pandas
cat > requirements.txt <<'EOF'
pandas==2.2.0
sqlalchemy==2.0.30
EOF
git add requirements.txt
GIT_COMMITTER_DATE="2026-01-13T10:00:00" git commit -q -m "chore: bump pandas to 2.2" --date "2026-01-13T10:00:00"

# main commit 4: refactor: extract load_orders signature (typed)
cat > src/etl.py <<'EOF'
"""ETL: extract, transform, load orders."""

from __future__ import annotations

import pandas as pd

from src.db import engine


def extract(path: str) -> pd.DataFrame:
    return pd.read_csv(path)


def transform(df: pd.DataFrame) -> pd.DataFrame:
    df["total"] = df["qty"] * df["price"]
    return df


def load_orders(df: pd.DataFrame, table: str) -> int:
    """Load orders to warehouse. Returns row count."""
    raise NotImplementedError
EOF
git add src/etl.py
GIT_COMMITTER_DATE="2026-01-14T10:00:00" git commit -q -m "refactor: extract load_orders signature" --date "2026-01-14T10:00:00"

# main commit 5: fix: handle empty dataframe in transform
cat > src/etl.py <<'EOF'
"""ETL: extract, transform, load orders."""

from __future__ import annotations

import pandas as pd

from src.db import engine


def extract(path: str) -> pd.DataFrame:
    return pd.read_csv(path)


def transform(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty:
        return df
    df["total"] = df["qty"] * df["price"]
    return df


def load_orders(df: pd.DataFrame, table: str) -> int:
    """Load orders to warehouse. Returns row count."""
    raise NotImplementedError
EOF
git add src/etl.py
GIT_COMMITTER_DATE="2026-01-15T10:00:00" git commit -q -m "fix: handle empty dataframe in transform" --date "2026-01-15T10:00:00"

# ============================================================
# feature/etl-loader: 3 messy commits
# ============================================================

git checkout -q feature/etl-loader

# feature commit 1: add load_orders function (no type hints, no engine import)
cat > src/etl.py <<'EOF'
"""ETL: extract, transform, load orders."""

import pandas as pd

from src.db import engine


def extract(path):
    return pd.read_csv(path)


def transform(df):
    df["total"] = df["qty"] * df["price"]
    return df


def load_orders(df, table):
    rows = len(df)
    df.to_sql(table, engine, if_exists="append", index=False)
    return rows
EOF
git add src/etl.py
GIT_COMMITTER_DATE="2026-01-12T11:00:00" git commit -q -m "add load_orders function" --date "2026-01-12T11:00:00"

# feature commit 2: add tests for load_orders (touches a different file — won't conflict)
cat > tests/test_load_orders.py <<'EOF'
"""Tests for load_orders."""

from unittest.mock import MagicMock

import pandas as pd
import pytest


def test_load_orders_returns_row_count(monkeypatch):
    """load_orders returns the number of rows loaded."""
    from src import etl

    fake_to_sql = MagicMock()
    monkeypatch.setattr(pd.DataFrame, "to_sql", fake_to_sql)

    df = pd.DataFrame({"id": [1, 2, 3], "amount": [10.0, 20.0, 30.0]})
    rows = etl.load_orders(df, "fact_orders")

    assert rows == 3
    fake_to_sql.assert_called_once()


def test_load_orders_handles_empty_dataframe():
    """load_orders returns 0 for empty dataframe and does not raise."""
    from src import etl

    df = pd.DataFrame(columns=["id", "amount"])
    rows = etl.load_orders(df, "fact_orders")

    assert rows == 0
EOF
git add tests/test_load_orders.py
GIT_COMMITTER_DATE="2026-01-13T11:00:00" git commit -q -m "add tests for load_orders" --date "2026-01-13T11:00:00"

# feature commit 3: WIP fix typo (sloppy commit — small change to test file)
python3 - <<'PY'
import pathlib
p = pathlib.Path("tests/test_load_orders.py")
text = p.read_text()
text = text.replace('"""Tests for load_orders."""',
                    '"""Tests for load_orders function."""')
p.write_text(text)
PY
git add tests/test_load_orders.py
GIT_COMMITTER_DATE="2026-01-13T11:30:00" git commit -q -m "WIP fix typo" --date "2026-01-13T11:30:00"

# ============================================================
# Bare remote
# ============================================================

git init --bare -q "$REMOTE_DIR"
git remote add origin "$REMOTE_DIR"
git push -q origin main
git push -q origin feature/etl-loader

# Stay on feature branch so the learner is in the right place
git checkout -q feature/etl-loader

echo ""
echo "Done. You are now on feature/etl-loader inside: $TARGET"
echo ""
echo "Current state:"
git log --oneline --graph --all --decorate | sed 's/^/  /'
echo ""
echo "Next: read README.md (in the lab folder) and start at Step 1."
