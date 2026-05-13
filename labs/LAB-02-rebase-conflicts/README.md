# LAB-02: Interactive rebase + разрешение конфликта

**Время:** ~2 часа
**Уровень:** Junior -> Middle
**Связан с модулями:** 06 (Конфликты), 07 (Rebase)

## Цель

Сценарий типичного дня Junior DE. Ты делал фичу в `feature/etl-loader`, а пока ты работал, кто-то из коллег смержил в `main` свой PR, который трогает тот же файл `src/etl.py`. Тимлид просит:

1. Прибрать твою feature-историю: 3 коммита превратить в 1 чистый, с правильным сообщением.
2. Поверх обновлённого `main` сделать rebase.
3. Разрешить merge conflict в `src/etl.py`.
4. Force-push безопасно (с `--force-with-lease`, не `--force`).

После лабы ты впервые без страха будешь делать `git rebase -i HEAD~3` и переписывать историю на feature-ветке.

## Что понадобится

- `git` 2.54+.
- Терминал bash/zsh.
- Никаких удалённых сервисов — всё локально.

## Шаг 0. Подготовить тренировочный репозиторий

Используем `setup.sh`, который создаёт изолированный репо со специально приготовленной историей.

```bash
LAB_DIR="<абсолютный путь до labs/LAB-02-rebase-conflicts>"
bash "$LAB_DIR/setup.sh" ~/de-projects/lab02-rebase
cd ~/de-projects/lab02-rebase
```

`setup.sh` идемпотентен — если вызвать повторно, он удалит старую папку и создаст её заново. Можешь смело перезапускать, если запутаешься.

После setup ты окажешься на ветке `feature/etl-loader`. Посмотри стартовое состояние:

```bash
git log --oneline --graph --all
```

Должно быть примерно так:

```
* <sha> (HEAD -> feature/etl-loader) WIP fix typo
* <sha> add tests for load_orders
* <sha> add load_orders function
| * <sha> (main) fix: handle empty dataframe in transform
| * <sha> refactor: extract load_orders signature
| * <sha> chore: bump pandas to 2.2
| * <sha> docs: update README
| * <sha> feat: initial etl skeleton
|/
* <sha> chore: initial commit
```

Обрати внимание:
- `feature/etl-loader` отделилась от `main` после первого коммита.
- `main` ушёл вперёд на 5 коммитов.
- На обеих ветках есть изменения в `src/etl.py` — это будущий конфликт (только в одном коммите feature-ветки, который трогает `src/etl.py`).
- Второй и третий коммиты feature-ветки трогают только `tests/test_load_orders.py` — там конфликта не будет.

## Шаг 1. Прибраться в feature-истории через interactive rebase

Текущая история feature-ветки уродливая:

```
* WIP fix typo                <- хочу спрятать в предыдущий коммит (fixup)
* add tests for load_orders   <- хочу оставить
* add load_orders function    <- хочу оставить, но переименовать (reword)
```

Запусти interactive rebase на 3 последних коммита:

```bash
git rebase -i HEAD~3
```

Откроется редактор (по умолчанию vi/vim, можно настроить через `git config --global core.editor "code --wait"` для VS Code или `"nano"`). Список коммитов будет в обратном порядке (сверху — самый старый):

```
pick <sha> add load_orders function
pick <sha> add tests for load_orders
pick <sha> WIP fix typo
```

Поменяй на:

```
reword <sha> add load_orders function
pick   <sha> add tests for load_orders
fixup  <sha> WIP fix typo
```

- `reword` — git остановится и даст переписать сообщение коммита.
- `fixup` — склеит коммит с предыдущим, его сообщение выкинет.

Сохрани и закрой редактор. Дальше git предложит переписать первое сообщение — замени его на:

```
feat: add load_orders with error handling
```

Сохрани, закрой. Rebase отработает. Проверь:

```bash
git log --oneline
```

Должно остаться 2 коммита feature-ветки + базовый — итого `git log feature/etl-loader ^main` покажет 2 коммита.

## Шаг 2. Rebase на актуальный main

Сначала убедись, что у тебя нет несохранённых изменений:

```bash
git status
# nothing to commit, working tree clean
```

Делаем rebase:

```bash
git rebase main
```

Git попытается воспроизвести твои коммиты поверх `main` и поймает конфликт:

```
Auto-merging src/etl.py
CONFLICT (content): Merge conflict in src/etl.py
error: could not apply <sha>... feat: add load_orders with error handling
```

## Шаг 3. Разрешить конфликт в src/etl.py

Открой `src/etl.py`:

```bash
cat src/etl.py
```

Внутри будут маркеры конфликта:

```
<<<<<<< HEAD
def load_orders(df: pd.DataFrame, table: str) -> int:
    """Load orders to warehouse. Returns row count."""
    ...
=======
def load_orders(df, table):
    rows = len(df)
    df.to_sql(table, engine, if_exists="append", index=False)
    return rows
>>>>>>> <sha> (feat: add load_orders with error handling)
```

Что нужно понять:
- `HEAD` (верхняя часть) — это **main**, потому что rebase сначала переключается на main, потом «приклеивает» твои коммиты сверху. В rebase HEAD и feature на момент конфликта **меняются местами по сравнению с merge**.
- Нижняя часть после `=======` — твой коммит, который git пытается применить.

Финальная версия `src/etl.py` должна:

1. Сохранить типизацию из `main` (`df: pd.DataFrame, table: str -> int`).
2. Сохранить твой error handling и логирование из feature.
3. Использовать `engine` импортированный из `src/db.py` (уже есть в main).

Целевой код (точное содержимое в `expected.md`):

```python
"""ETL: load orders into warehouse."""

from __future__ import annotations

import logging

import pandas as pd

from src.db import engine

logger = logging.getLogger(__name__)


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

Удали все маркеры `<<<<<<<`, `=======`, `>>>>>>>`. Сохрани.

Скажи git, что конфликт разрешён, и продолжи rebase:

```bash
git add src/etl.py
git rebase --continue
```

Если был ещё коммит, git может попросить продолжить с него. Делай `git status` после каждой остановки — если конфликтов больше нет, продолжай `--continue`.

Когда rebase закончится, проверь:

```bash
git log --oneline --graph --all
```

Теперь твоя ветка должна идти линейно от верхушки `main`:

```
* <sha> (HEAD -> feature/etl-loader) add tests for load_orders
* <sha> feat: add load_orders with error handling
* <sha> (main) fix: handle empty dataframe in transform
* <sha> refactor: extract load_orders signature
* <sha> chore: bump pandas to 2.2
* <sha> docs: update README
* <sha> feat: initial etl skeleton
* <sha> chore: initial commit
```

Никаких merge-коммитов, никакого «islands of branches» в графе.

## Шаг 4. Force-push безопасно

В `setup.sh` уже добавлен fake remote — это локальный bare-репозиторий в `../lab02-remote.git`. Обычный `git push` упрётся в non-fast-forward, потому что ты переписал историю:

```bash
git push origin feature/etl-loader
# ! [rejected]        feature/etl-loader -> feature/etl-loader (non-fast-forward)
```

**НЕЛЬЗЯ** делать `git push --force` — это может затереть чужие коммиты, если кто-то успел добавить commit в твою ветку, пока ты ребейзил.

**НУЖНО** использовать `--force-with-lease`:

```bash
git push --force-with-lease origin feature/etl-loader
```

`--force-with-lease` сначала проверяет, что remote ref всё ещё указывает на ту версию, которую ты видел в последний раз. Если кто-то запушил поверх — git откажется. Это «безопасный форс».

Проверь:

```bash
git push origin feature/etl-loader
# Everything up-to-date
```

## Шаг 5. Запустить verify.sh

```bash
bash <LAB_DIR>/verify.sh ~/de-projects/lab02-rebase
```

verify.sh проверит:

- ветка `feature/etl-loader` существует и линейно отделена от `main` (нет merge-коммитов).
- ровно 2 коммита на `feature/etl-loader` относительно `main` (после squash).
- `src/etl.py` не содержит маркеров конфликта.
- `src/etl.py` содержит финальную сигнатуру `def load_orders(df: pd.DataFrame, table: str) -> int:`.
- `src/etl.py` обрабатывает пустой dataframe.
- Импорт `engine` из `src.db` присутствует.
- Force push сделан (если есть remote — `git rev-parse origin/feature/etl-loader` совпадает с локальным HEAD).

## Чеклист самопроверки

- [ ] `git rebase -i HEAD~3` отработал без ошибок.
- [ ] WIP-коммит «съеден» через `fixup`.
- [ ] Первый коммит переименован через `reword`.
- [ ] `git rebase main` дошёл до конца, конфликт разрешён.
- [ ] `src/etl.py` собрал лучшее из обеих сторон: типизация + error handling + правильный импорт.
- [ ] История feature-ветки линейная (`git log --graph` без вилок).
- [ ] Force-push сделан через `--force-with-lease`.
- [ ] `verify.sh` без `[FAIL]`.

## Что делать, если запутался

1. **`git rebase --abort`** — отменяет текущий rebase и возвращает ветку в исходное состояние. Безопасно.
2. **`git reflog`** — список всех движений HEAD. Можно вернуться к любому состоянию командой `git reset --hard HEAD@{N}`.
3. **Полный сброс**: `bash setup.sh ~/de-projects/lab02-rebase` — пересоздаст репо с нуля.

Подсказки по командам — в `hints.md` (но не подсматривай, пока не попробуешь сам минут 20).

## Чему ты научился

- Различать `pick / reword / squash / fixup / drop` в interactive rebase.
- Понимать, почему в rebase `HEAD` — это базовая ветка, а не feature.
- Использовать `--force-with-lease` вместо `--force` для безопасного push.
- Восстанавливаться через `git rebase --abort` и `git reflog`.
