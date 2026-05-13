# {{project_name}}

{{one_sentence_description}}

## Что внутри

ETL-пайплайн для {{data_domain}}. Извлекает данные из {{source_system}}, трансформирует через Python/SQL, грузит в {{target_warehouse}}.

## Стек

- Python 3.11+
- Apache Airflow (DAGs в `dags/`)
- dbt для трансформаций (план: модели в `dbt/models/`)
- pytest для тестов
- pre-commit для линтеров и форматтеров

## Локальный запуск

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
pre-commit install
pre-commit run --all-files
```

## Структура репозитория

```
{{project_name}}/
├── dags/                 # Airflow DAGs
├── src/                  # Python модули (extract, transform, load)
├── tests/                # pytest тесты
├── dbt/                  # dbt models (план)
├── pyproject.toml
├── .pre-commit-config.yaml
└── .gitignore
```

## Workflow

1. Создай feature-ветку: `git checkout -b feat/<short-description>`.
2. Делай небольшие коммиты с понятными сообщениями (Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`).
3. Push, открой PR через `gh pr create`.
4. Дождись зелёного CI, попроси review.
5. После approve — merge через squash.

## Контакты

{{your_name}} — {{your_email}}

## Лицензия

MIT
