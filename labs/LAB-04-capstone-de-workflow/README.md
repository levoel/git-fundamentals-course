# LAB-04: Capstone — реальный DE-workflow от clone до merge

**Время выполнения**: 60-90 минут.

**Цель**: пройти полный day-1 workflow junior DE — от clone репозитория до merge feature PR, включая обработку review comments и разрешение конфликта.

**Что узнаешь**:
- Реалистичный onboarding в новый проект (15-min sweep).
- Conventional commits с ticket reference.
- Полный PR cycle: open -> CI -> review -> conflict resolution -> merge.
- Force push with `--force-with-lease`.
- Cleanup после merge.
- Hotfix mini-flow.

## Prerequisites

- Прошёл модули 01-19 курса Git для Junior DE.
- Git 2.54+ установлен (`git --version`).
- GitHub аккаунт + SSH-key настроен (модуль 02).
- GitHub CLI `gh` установлен и аутентифицирован (`gh auth status` показывает success).
- Python 3.13 + `uv` (для проверки локально).
- Pre-commit framework (для gitleaks hook).

## Сценарий

Ты твой первый день в DE-команде Acme Corp. Tech lead Alice прислала JIRA ticket `DE-1234`:

> **Title**: Add user_events ingestion DAG
> 
> **Description**: Marketing хочет видеть user behavior events в Snowflake. Сейчас events в S3 (Parquet, partitioned by date). Создай DAG, который daily в 04:00 UTC загружает их в `ANALYTICS.RAW.USER_EVENTS`. Idempotent (DELETE-then-COPY). Тесты + документация. CI должен быть зелёным.

Mock-репозиторий `mock-repo/` имитирует Airflow DAGs репо команды Acme Corp.

---

## Step 1: Setup mock environment (5 минут)

### 1.1 Initialize mock-repo как git репо

```bash
$ cd labs/LAB-04-capstone-de-workflow/mock-repo
$ git init
$ git add .
$ git commit -m "Initial commit: existing DAGs and tests"
```

### 1.2 Create GitHub repository (опционально, для full experience)

Чтобы прочувствовать real workflow (CI, gh pr create), создай в твоём GitHub новый репо:

```bash
$ gh repo create my-capstone-mock --public --source=. --remote=origin --push
```

Это создаст репо на GitHub под твоим аккаунтом и push current state. Если не хочешь использовать GitHub — продолжай локально без push/PR (но review и merge через UI ты упустишь).

### 1.3 Install dependencies (для local CI checks)

```bash
$ uv sync
$ pre-commit install
```

---

## Step 2: 15-минутный sweep репо (15 минут)

Не пиши код. Изучай:

### 2.1 Прочитай README

```bash
$ cat README.md
```

Понимай purpose проекта, conventions.

### 2.2 Look существующие DAGs

```bash
$ ls dags/
$ cat dags/fact_orders_dag.py
```

`fact_orders_dag.py` — самый похожий по теме (S3 -> Snowflake). Это твой template.

### 2.3 Shared utilities

```bash
$ cat dags/shared/snowflake_loaders.py
$ cat dags/shared/s3_utils.py
$ cat dags/shared/secret_helpers.py
```

Эти helpers переиспользуй в своём DAG.

### 2.4 CI workflow

```bash
$ cat .github/workflows/ci.yml
```

Понимай какие checks: ruff, mypy, pytest, gitleaks.

### 2.5 Recent commits

```bash
$ git log --oneline -10
```

Style messages — конвенция (feat:, fix:, docs:).

### 2.6 CODEOWNERS

```bash
$ cat .github/CODEOWNERS
```

Видишь, что `/dags/` owners — `@acme-corp/data-engineering`.

---

## Step 3: Создай feature branch (1 минута)

```bash
$ git switch -c feat/de-1234-user-events-dag
$ git branch --show-current
feat/de-1234-user-events-dag
```

---

## Step 4: Implement DAG (30-45 минут)

### 4.1 Создай `dags/user_events_dag.py`

Используй `fact_orders_dag.py` как template. Требования:

- DAG ID: `user_events_ingestion`.
- Schedule: `0 4 * * *` (04:00 UTC daily).
- Source: `s3://company-events-bucket/user_events/year={Y}/month={M}/day={D}/*.parquet`.
- Target: `ANALYTICS.RAW.USER_EVENTS`.
- Stage: используй `Variable.get('snowflake_s3_stage', default_var='@RAW.S3_STAGE_DEV')` для env-flexibility.
- Idempotent: `DELETE FROM ... WHERE event_date = ...` затем `COPY INTO`.
- `retries=2`, `retry_delay=timedelta(minutes=5)`.
- Owner: `data-engineering`.
- Connections: `snowflake_default`, `aws_default`.
- Docstring + type hints.

### 4.2 Commit DAG

```bash
$ git add dags/user_events_dag.py
$ git commit -m "feat(dags): add user_events ingestion DAG

Daily load of S3 user_events parquet partitions to
Snowflake ANALYTICS.RAW.USER_EVENTS. Idempotent: pre-deletes
partition before copy.

Refs: DE-1234"
```

### 4.3 Создай tests/test_user_events.py

3 теста:

1. `test_dag_imports_without_error` — smoke test: DAG-файл импортируется.
2. `test_dag_has_expected_tasks` — содержит `delete_existing_partition` + `copy_into_snowflake`.
3. `test_dag_schedule_is_daily_04` — schedule == `0 4 * * *`.

```bash
$ uv run pytest tests/test_user_events.py -v
```

Все 3 теста зелёные? Commit:

```bash
$ git add tests/test_user_events.py
$ git commit -m "test(user_events_dag): add smoke + schedule + tasks tests

Refs: DE-1234"
```

### 4.4 Обнови dags/README.md

Добавь секцию о новом DAG: purpose, schedule, source, target, owner, idempotency, ticket.

```bash
$ git add dags/README.md
$ git commit -m "docs(dags): document user_events_ingestion DAG

Refs: DE-1234"
```

### 4.5 Локальная проверка

```bash
$ uv run ruff check .
$ uv run ruff format --check .
$ uv run mypy dags/ tests/
$ uv run pytest -v
```

Всё зелёное? Готов к push.

---

## Step 5: Push & PR (5 минут)

### 5.1 Push с upstream

```bash
$ git push --set-upstream origin feat/de-1234-user-events-dag
```

### 5.2 Open PR

Через `gh`:

```bash
$ gh pr create \
    --base main \
    --title "feat(dags): add user_events ingestion DAG (DE-1234)" \
    --body-file ../expected-pr/PR_BODY.md
```

Или через GitHub UI: https://github.com/<your-user>/my-capstone-mock/pull/new/feat/de-1234-user-events-dag.

PR body — см. `../expected-pr/PR_BODY.md` для reference.

### 5.3 Wait CI green

```bash
$ gh pr checks
```

Если есть failures — fix, push, повтори.

---

## Step 6: Simulate code review (15 минут)

В реальном сценарии Alice оставит review comments. Здесь — **симуляция**: открой `../expected-pr/REVIEW_COMMENTS.md`. В нём 5 comments разных типов.

Для каждого:

1. Определи тип (blocker / suggestion / nit / question / praise).
2. Реши, какую реакцию: fix/discuss/no-action.
3. Если fix — внеси изменения, commit, push.
4. В PR comment-е (или в response file `your-responses.md`) напиши response в правильном style.

### Comment 1 (blocker)

```
SNOWFLAKE_STAGE = "@RAW.S3_STAGE" hardcoded. Use Variable.get() per fact_orders_dag.py.
```

Fix: применить `Variable.get('snowflake_s3_stage', default_var='@RAW.S3_STAGE_DEV')`.

```bash
$ git add dags/user_events_dag.py
$ git commit -m "fix(user_events_dag): use Variable.get() for stage name

Per review: env-specific config from Airflow Variables, not hardcoded.

Refs: DE-1234"
$ git push
```

Response в PR comment:
```
Good catch — switched to Variable.get() in <commit-sha>. Tested locally by setting
AIRFLOW_VAR_SNOWFLAKE_S3_STAGE override. Resolves issue.
```

### Comment 2 (suggestion)

```
Use timedelta(minutes=5) instead of bare 300.
```

Fix: import `timedelta`, change `retry_delay=300` -> `retry_delay=timedelta(minutes=5)`.

Commit + push + response.

### Comment 3 (nit)

```
nit: add 'Tables written' section to docstring per analytics_main_etl_dag.py.
```

Fix (quick, 30 sec): добавить секцию в docstring.

### Comment 4 (question)

```
Why `>>` instead of chain()?
```

No code change. Response:
```
For 2-task DAG `>>` reads cleaner. I'd switch to chain() if we add a third task.
```

### Comment 5 (praise)

```
Nice idempotency design — DELETE-then-INSERT.
```

Short thanks:
```
Thanks! Learned from fact_orders_dag.
```

---

## Step 7: Conflict resolution (15 минут)

### 7.1 Симулируем "main продвинулся"

Откройте новый terminal, в нём:

```bash
$ cd labs/LAB-04-capstone-de-workflow/mock-repo
$ git checkout main
$ git pull  # если есть remote

# Симулируем PR другой команды: они изменили snowflake_loaders.py
# Меняем default ON_ERROR с 'CONTINUE' на 'ABORT_STATEMENT'
$ sed -i.bak "s/ON_ERROR = 'CONTINUE'/ON_ERROR = 'ABORT_STATEMENT'/" dags/shared/snowflake_loaders.py
$ rm dags/shared/snowflake_loaders.py.bak
$ git add dags/shared/snowflake_loaders.py
$ git commit -m "fix(snowflake_loaders): change ON_ERROR default to ABORT_STATEMENT

Safer default: don't silently skip bad rows in production COPY.

Refs: DE-1235"

# Push в main (или симулируй через локальный)
$ git push
```

### 7.2 Назад в feature branch, rebase

```bash
$ git checkout feat/de-1234-user-events-dag
$ git fetch origin
$ git rebase origin/main
```

Конфликт в `dags/shared/snowflake_loaders.py`. Открой файл, выбери правильное решение (Alice version — `ABORT_STATEMENT`):

```bash
$ vim dags/shared/snowflake_loaders.py
# resolve conflict markers
$ git add dags/shared/snowflake_loaders.py
$ git rebase --continue
```

### 7.3 Verify locally

```bash
$ uv run pytest -v
$ uv run ruff check .
$ uv run mypy dags/ tests/
```

Зелёное.

### 7.4 Force push с --force-with-lease

```bash
$ git push --force-with-lease
```

### 7.5 PR comment

```
Rebased on latest main, resolved conflict in snowflake_loaders.py (took
ABORT_STATEMENT change from #790). All tests still pass.
```

---

## Step 8: Merge (5 минут)

### 8.1 GitHub UI или через gh

```bash
$ gh pr merge --squash --delete-branch
```

(или GitHub UI: Squash and merge button -> confirm.)

### 8.2 Cleanup local

```bash
$ git switch main
$ git pull
$ git branch -d feat/de-1234-user-events-dag
$ git fetch --prune
```

### 8.3 Verify

```bash
$ git log --oneline -5
$ git branch -a
# Только main, никакого feat/...
```

---

## Step 9: Hotfix simulation (10 минут)

Alice пинг: «typo в README, quick fix?».

```bash
# 1. Fresh main
$ git checkout main
$ git pull

# 2. Short-lived branch
$ git switch -c hotfix/readme-typo

# 3. Fix typo (preopened typo `Inegstion` -> `Ingestion` в README.md)
$ sed -i.bak 's/Inegstion/Ingestion/g' README.md
$ rm README.md.bak

$ git diff
$ git add README.md
$ git commit -m "docs: fix typo in README

Inegstion -> Ingestion"

# 4. Push + PR
$ git push -u origin hotfix/readme-typo
$ gh pr create --base main --title "docs: fix typo in README" \
    --body "Fixes typo Inegstion -> Ingestion. Trivial."

# 5. Merge (можно сам approve в mock-сценарии)
$ gh pr merge --squash --delete-branch

# 6. Cleanup
$ git switch main
$ git pull
$ git fetch --prune
```

---

## Completion checklist

- [ ] Clone и 15-min sweep репо.
- [ ] Feature branch с conventional name (`feat/de-1234-user-events-dag`).
- [ ] DAG `dags/user_events_dag.py` создан и работает (idempotent, Variable.get for stage, timedelta for retry_delay).
- [ ] 3 теста в `tests/test_user_events.py` зелёные.
- [ ] README.md обновлён с DAG documentation.
- [ ] Локальный CI зелёный (ruff, mypy, pytest, gitleaks).
- [ ] Push с `--set-upstream`.
- [ ] PR open с meaningful body (Summary, Changes, Testing, Acceptance Criteria).
- [ ] CI зелёный на PR (если используешь GitHub).
- [ ] Все 5 review comments addressed с правильным response style.
- [ ] Rebase на updated main выполнен.
- [ ] Conflict в `snowflake_loaders.py` resolved semantically.
- [ ] Force push с `--force-with-lease`.
- [ ] PR merged через Squash.
- [ ] Cleanup: branch deleted local + remote, prune fetched.
- [ ] Hotfix flow: short-lived branch, fix, PR, merge — за 5 минут.

## Reflection

После завершения:

1. **Что было самое сложное?** Часто — conflict resolution с semantic thinking, не mechanical.
2. **Что бы сделал по-другому?** На второй раз — заранее знаешь pitfalls.
3. **Какой части курса не хватало?** Это feedback для improvements.

## Resources

- `mock-repo/` — стартовая точка lab.
- `expected-pr/` — examples PR body, review comments, responses, final DAG implementation.
- Курс модули 17-20 — все techniques.

---

**Поздравляю с завершением capstone!** Ты прошёл день-1 cycle junior DE. Готов к real production team.

Next step: сделай 5 merged PRs в open-source DE projects. Best learning is real review.
