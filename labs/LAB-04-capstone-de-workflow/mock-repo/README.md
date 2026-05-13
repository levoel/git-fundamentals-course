# analytics-dags

Airflow DAGs репозитория Acme Corp data-engineering команды.

## Структура

```
.
├── dags/                       # Airflow DAGs
│   ├── README.md               # документация по DAGs
│   ├── analytics_main_etl_dag.py
│   ├── campaign_data_dag.py
│   ├── fact_orders_dag.py
│   └── shared/                 # переиспользуемые helpers
│       ├── __init__.py
│       ├── s3_utils.py
│       ├── snowflake_loaders.py
│       └── secret_helpers.py
├── tests/                      # pytest tests for DAGs
├── .github/
│   ├── workflows/
│   │   └── ci.yml
│   └── CODEOWNERS
├── pyproject.toml
└── README.md
```

## Setup для разработки

```bash
$ uv sync
$ pre-commit install
$ uv run pytest -v
```

## Conventions

### Branch naming

- `feat/<jira-id>-<slug>` — новая feature
- `fix/<jira-id>-<slug>` — bug fix
- `docs/<slug>` — документация
- `hotfix/<slug>` — срочное исправление

### Commit messages

Используем [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(scope): summary

Optional longer description.

Refs: JIRA-1234
```

Types: `feat`, `fix`, `docs`, `chore`, `test`, `refactor`, `style`, `perf`.

### Inegstion Pipelines

(Опечатка — должно быть Ingestion. Это для hotfix simulation в Step 9 capstone.)

Список текущих ingestion pipelines:

- `fact_orders_dag` — orders from S3 daily.
- `campaign_data_dag` — marketing attribution.
- `analytics_main_etl_dag` — main analytics ETL.

## Tech stack

- Python 3.13
- Apache Airflow 2.10
- dbt-snowflake 1.9
- uv для package management
- ruff, mypy, pytest для quality

## Owners

- Tech leads: `@acme-corp/tech-leads`
- DE team: `@acme-corp/data-engineering`
