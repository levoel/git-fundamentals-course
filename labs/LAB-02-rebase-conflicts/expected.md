# Ожидаемый результат LAB-02

## Финальная история (git log --oneline --graph --all)

После корректного выполнения шагов история должна выглядеть линейно — без merge-коммитов, без вилок:

```
* <sha> (HEAD -> feature/etl-loader, origin/feature/etl-loader) add tests for load_orders
* <sha> feat: add load_orders with error handling
* <sha> (main, origin/main) fix: handle empty dataframe in transform
* <sha> refactor: extract load_orders signature
* <sha> chore: bump pandas to 2.2
* <sha> docs: update README
* <sha> feat: initial etl skeleton
* <sha> chore: initial commit
```

Ключевое:

- На `feature/etl-loader` относительно `main` ровно **2 коммита** (после squash трёх в один с `fixup` + сохранение второго коммита). Допустимый вариант — 1 коммит, если сделал больше `fixup`-ов.
- `feature/etl-loader` начинается **прямо от верхушки `main`** (rebase).
- Никаких merge-коммитов в виде `Merge branch 'main' into feature/etl-loader`.
- Force-push прошёл — `origin/feature/etl-loader` равно локальной HEAD.

## Финальный src/etl.py

```python
"""ETL: extract, transform, load orders."""

from __future__ import annotations

import logging

import pandas as pd

from src.db import engine

logger = logging.getLogger(__name__)


def extract(path: str) -> pd.DataFrame:
    return pd.read_csv(path)


def transform(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty:
        return df
    df["total"] = df["qty"] * df["price"]
    return df


def load_orders(df: pd.DataFrame, table: str) -> int:
    """Load orders to warehouse. Returns row count.

    Raises:
        ValueError: if dataframe is empty.
    """
    if df.empty:
        logger.warning("load_orders called with empty dataframe; skipping")
        return 0

    rows = len(df)
    logger.info("loading %d rows into %s", rows, table)
    df.to_sql(table, engine, if_exists="append", index=False)
    return rows
```

Что должно быть собрано из обеих сторон:

| Источник | Что взяли |
|---|---|
| main | типизация: `df: pd.DataFrame, table: str -> int`; `from __future__ import annotations`; импорт `engine` из `src.db`; обработка empty в `transform` |
| feature | `logging.getLogger`; обработка `if df.empty` в `load_orders`; `df.to_sql(table, engine, ...)`; реальная реализация (а не `raise NotImplementedError`) |

## Что точно НЕ должно быть в финальном файле

- Маркеров `<<<<<<<`, `=======`, `>>>>>>>`.
- `raise NotImplementedError` в `load_orders` (это была заглушка main, твоя задача — заменить реальной реализацией).
- `df["total"] = df["qty"] * df["price"]` без проверки на empty (мы оставляем версию из main).
- Дублированных импортов `engine`.

## Если есть удалённый репозиторий

`setup.sh` создаёт bare-remote в `<target>-remote.git`. После rebase обычный push отклонится:

```
! [rejected]        feature/etl-loader -> feature/etl-loader (non-fast-forward)
```

Это ожидаемо — ты переписал историю. Правильный путь:

```bash
git push --force-with-lease origin feature/etl-loader
```

**Никогда** в реальной работе не делай `git push --force` без `--with-lease` — это может затереть коммиты коллеги, которые он успел запушить в твою ветку.
