# LAB-01: Bootstrap нового DE-проекта с Git + pre-commit

**Время:** ~1.5 часа
**Уровень:** Junior
**Связан с модулями:** 02 (Установка и настройка), 13 (.gitignore), 15 (Хуки и pre-commit)

## Цель

Завести с нуля Python-репозиторий под Data Engineering pipeline — так, как это делается в нормальной команде. Не «git init и закоммитил всё подряд», а с правильным `.gitignore`, pre-commit hooks, README и PR через GitHub CLI.

После этой лабы у тебя будет публичный GitHub-репозиторий, который не стыдно показать в качестве портфолио, и привычка с первой минуты нового проекта прогонять `pre-commit run --all-files`.

## Что понадобится

- Установленный `git` (`git --version` -> 2.54+)
- Python 3.11+ и `pip`
- GitHub-аккаунт + установленный `gh` CLI (`gh auth status` -> залогинен)
- Терминал bash или zsh

Проверь окружение одной командой:

```bash
git --version && python3 --version && gh --version && gh auth status
```

Если `gh auth status` ругается — выполни `gh auth login` и пройди браузерную авторизацию.

## Что сделаешь

1. Создашь пустую папку и инициализируешь git-репозиторий.
2. Настроишь `git config` (имя, email — если ещё не настроены глобально).
3. Скопируешь готовый `.gitignore`, `pyproject.toml`, `.pre-commit-config.yaml` из `templates/`.
4. Напишешь README.md по шаблону.
5. Создашь GitHub-репозиторий через `gh` и запушишь main.
6. Установишь pre-commit и прогонишь его на всех файлах.
7. Создашь feature-ветку `feat/initial-pipeline` со скелетом Airflow DAG.
8. Откроешь PR в свой же репозиторий через `gh pr create`.
9. Запустишь `verify.sh` и убедишься, что всё зелёное.

## Шаг 1. Создать папку и инициализировать репозиторий

```bash
mkdir -p ~/de-projects/orders-pipeline
cd ~/de-projects/orders-pipeline
git init -b main
```

Флаг `-b main` создаёт ветку `main` сразу (без устаревшего `master`).

Проверь:

```bash
git status
git symbolic-ref HEAD
# refs/heads/main
```

## Шаг 2. Настроить git config

Если у тебя ещё не настроены глобальные `user.name` и `user.email`:

```bash
git config --global user.name "Имя Фамилия"
git config --global user.email "you@example.com"
```

Проверь:

```bash
git config --get user.name
git config --get user.email
```

Email должен совпадать с тем, что привязан к GitHub-аккаунту — иначе коммиты не будут отображаться как твои.

## Шаг 3. Скопировать шаблоны

Из этой папки лабы скопируй три файла в новый репозиторий. Замени `<LAB_DIR>` на абсолютный путь до этой лабы:

```bash
LAB_DIR="<абсолютный путь до labs/LAB-01-bootstrap-de-project>"
cp "$LAB_DIR/templates/.gitignore" .
cp "$LAB_DIR/templates/.pre-commit-config.yaml" .
cp "$LAB_DIR/templates/pyproject.toml" .
cp "$LAB_DIR/templates/README.template.md" README.md
```

Проверь, что файлы на месте:

```bash
ls -la
# должны быть: .git/  .gitignore  .pre-commit-config.yaml  pyproject.toml  README.md
```

## Шаг 4. Заполнить README

Открой `README.md` и замени плейсхолдеры в фигурных скобках на свои значения (имя проекта, описание, твоё имя). Не оставляй `{{...}}` в финальном файле — `verify.sh` это проверит.

## Шаг 5. Создать GitHub-репозиторий и запушить main

Сначала сделай первый локальный коммит — чтобы было что пушить:

```bash
git add .gitignore pyproject.toml README.md .pre-commit-config.yaml
git commit -m "chore: bootstrap project with gitignore, pre-commit, pyproject"
```

Создай удалённый репозиторий через `gh` (он сам выставит `origin` и запушит):

```bash
gh repo create orders-pipeline --public --source=. --remote=origin --push
```

Проверь:

```bash
git remote -v
# origin  https://github.com/<твой-username>/orders-pipeline.git (fetch)
# origin  https://github.com/<твой-username>/orders-pipeline.git (push)

git branch -vv
# * main <sha> [origin/main] chore: bootstrap project ...
```

## Шаг 6. Установить и активировать pre-commit

```bash
python3 -m pip install --user pre-commit
pre-commit --version
# pre-commit 3.x.x

pre-commit install
# pre-commit installed at .git/hooks/pre-commit
```

Прогоняем на всех файлах (первый запуск долгий — pre-commit подтягивает окружения для каждого хука):

```bash
pre-commit run --all-files
```

Если ruff что-то отформатирует — это нормально, тебе нужно будет закоммитить изменения:

```bash
git status
git add -u
git commit -m "style: apply ruff formatting"
```

Прогоняй `pre-commit run --all-files` снова, пока всё не будет зелёное.

## Шаг 7. Feature-ветка со скелетом DAG

```bash
git checkout -b feat/initial-pipeline

mkdir -p dags
cat > dags/orders_etl.py <<'PYEOF'
"""Skeleton DAG for orders pipeline. Real implementation will land in follow-up PRs."""

from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator

DAG_ID = "orders_etl"

with DAG(
    dag_id=DAG_ID,
    start_date=datetime(2026, 1, 1),
    schedule="@daily",
    catchup=False,
    tags=["orders", "etl"],
) as dag:
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end")

    start >> end
PYEOF

git add dags/orders_etl.py
git commit -m "feat: add skeleton orders_etl DAG"
git push -u origin feat/initial-pipeline
```

Pre-commit прогонится автоматически при `git commit`. Если ругается на форматирование — поправь, сделай `git add -u && git commit --amend --no-edit`, потом снова `git push`.

## Шаг 8. Открыть PR через gh

```bash
gh pr create \
  --title "feat: skeleton orders ETL DAG" \
  --body "Adds empty Airflow DAG as a placeholder. Real tasks land in follow-up PRs (extract, transform, load)."
```

`gh` распечатает URL созданного PR. Открой его в браузере — убедись, что:

- PR действительно из `feat/initial-pipeline` в `main`.
- В описании есть текст, который ты передал в `--body`.
- В diff виден `dags/orders_etl.py`.

## Шаг 9. Запустить verify.sh

```bash
bash <LAB_DIR>/verify.sh ~/de-projects/orders-pipeline
```

Скрипт проверит:

- `.git/` существует, ветка по умолчанию `main`.
- `.gitignore`, `.pre-commit-config.yaml`, `pyproject.toml`, `README.md` на месте.
- README без `{{плейсхолдеров}}`.
- `pre-commit` установлен как git hook (`.git/hooks/pre-commit`).
- `pre-commit run --all-files` проходит без ошибок.
- `git remote get-url origin` отвечает.
- Существует ветка `feat/initial-pipeline` со скелетом DAG.
- Минимум 2 коммита в `main` или PR в открытом состоянии.

Все строки должны быть `[OK]`. Если есть `[FAIL]` — читай вывод и чини шаг, который указан.

## Что должно быть в финальной истории

Минимально:

```
* <sha> (HEAD -> feat/initial-pipeline, origin/feat/initial-pipeline) feat: add skeleton orders_etl DAG
* <sha> (origin/main, main) chore: bootstrap project with gitignore, pre-commit, pyproject
```

Пример референсной истории — в `.expected/git-log.txt`.

## Чеклист самопроверки

- [ ] `git init -b main` отработал, ветка по умолчанию — `main`.
- [ ] `.gitignore` запушен и блокирует `__pycache__/`, `.env`, `*.parquet`.
- [ ] `.pre-commit-config.yaml` настроен с ruff (format + check), mypy, nbstripout, gitleaks.
- [ ] `pre-commit install` сделан — есть файл `.git/hooks/pre-commit`.
- [ ] `pre-commit run --all-files` зелёное.
- [ ] GitHub-репозиторий создан через `gh repo create`.
- [ ] Ветка `feat/initial-pipeline` запушена.
- [ ] PR открыт через `gh pr create`, URL получен.
- [ ] `verify.sh` без `[FAIL]`.

## Типичные ошибки

- **`gh auth login` зависает в браузере** — попробуй `gh auth login --web` или `--device`, выбери HTTPS, не SSH.
- **`pre-commit run` падает на gitleaks** — это значит, что в репозитории есть строка, похожая на секрет. Проверь, что ты не закоммитил `.env` или API-ключ.
- **`gh repo create` ругается на existing remote** — у тебя уже добавлен `origin`. Убери его: `git remote remove origin`, повтори.
- **ruff format меняет файлы, и pre-commit падает** — это норма для первого запуска. Закоммить изменения, прогони снова.
