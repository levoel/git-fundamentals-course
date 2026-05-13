# Git для Junior Data Engineer

Бесплатный практический курс по Git для будущего Junior Data Engineer. От первого `git init` до восстановления потерянных коммитов через reflog, от настройки SSH-ключей до настройки CI на GitHub Actions.

Это не очередной «10 команд Git за 30 минут». Курс отвечает на вопросы вида «что именно лежит внутри `.git/objects/`, когда я делаю `git commit`», «почему `git pull --rebase` ломает мне `feature/etl-rewrite` на ровном месте», «как один-единственный pre-commit hook от data-команды защищает прод от `.env` с production-паролями». Каждая команда разбирается до уровня, на котором становится понятно **почему** она работает именно так — и что произойдёт, если её ошибочно применить к публичной ветке.

## Целевая аудитория

- **Будущий Junior Data Engineer** (1–3 года опыта в IT) — переходит в команду, где есть GitHub/GitLab, code review, CI, и от первого дня требуется уметь работать с веткой, делать PR, разруливать merge conflict.
- **Аналитик / ML-инженер**, у которого «всё в Jupyter и в Google Drive» — а на новом месте dbt-репозиторий, версионирование SQL-моделей и pre-commit hooks.
- **Бэкенд-разработчик** с опытом `git pull / git commit / git push`, который ни разу не делал rebase и боится reflog.

## Что внутри

**21 модуль** (~55 часов), синхронизирован с **Git 2.54+** (стабильная на май 2026):

| #  | Модуль | Что разбираем |
|----|---|---|
| 00 | Введение | О курсе, как читать, навигация |
| 01 | Что такое Git и VCS | История VCS (CVS -> SVN -> Git), DAG коммитов, distributed vs centralized |
| 02 | Установка и настройка | install, `git config`, identity, SSH/GPG keys, GitHub аккаунт |
| 03 | **Три дерева** * | Working tree, index (staging), repository, объекты blob/tree/commit, SHA-1/SHA-256 |
| 04 | Ветки и слияния | refs, HEAD, fast-forward, three-way merge, merge base |
| 05 | Удалённые репозитории | remote, origin, fetch vs pull, push, tracking branches, refspec |
| 06 | Конфликты слияния | Маркеры конфликта, mergetool, разбор реальных DE-конфликтов (dbt models, dags) |
| 07 | **Rebase** * | interactive rebase, squash, fixup, opasnost rewrite публичной истории |
| 08 | История и инспекция | `git log` formats, `git diff`, `git blame`, `git bisect` для поиска bad commit |
| 09 | **Отмена и reflog** * | `git reset --soft/--mixed/--hard`, `git revert`, `git reflog` как машина времени |
| 10 | Stash, tags, cherry-pick | Временное прятание, annotated/lightweight tags, перенос commits между ветками |
| 11 | Pull Requests | Anatomy PR, draft, review, suggested changes, merge / squash / rebase strategies |
| 12 | Git workflows | GitHub Flow, GitFlow, trunk-based — что выбрать DE-команде |
| 13 | .gitignore и .gitattributes | Patterns, negation, шаблоны для Python/Jupyter, line endings, diff drivers |
| 14 | Git LFS и большие данные | Зачем LFS, pointer files, как НЕ хранить parquet в git, DVC alternative |
| 15 | Хуки и pre-commit | client-side vs server-side hooks, pre-commit framework, black/ruff/sqlfluff |
| 16 | Submodules, worktrees | Когда использовать, типичные ловушки, multi-checkout одного репо |
| 17 | **Секреты и безопасность** * | gitleaks, BFG Repo-Cleaner, git-filter-repo, rotate-after-leak playbook |
| 18 | CI/CD с GitHub Actions | Workflow YAML, jobs, secrets, branch protection, status checks |
| 19 | Восстановление | reflog rescue, recovered detached HEAD, `git fsck`, dangling objects |
| 20 | **Capstone** * | Реальный DE-workflow: clone repo -> feature branch -> PR -> review -> CI green -> merge |

* = ключевой модуль, в котором курс уходит глубже типичных «git за неделю» материалов.

## Что выйдет на руках в конце

- Спокойно делать **PR на 200+ строк**, проходить code review, исправлять замечания через `git commit --fixup` + autosquash.
- Разруливать **merge conflict** в dbt-модели на 500 строк SQL, не сломав чужие изменения.
- Восстанавливать **«удалённую» ветку** через reflog после `git reset --hard HEAD~5`.
- Настроить **pre-commit** с ruff / black / sqlfluff / detect-secrets — так, чтобы коллеги тоже не пушили лишнее.
- Прочитать `.git/HEAD`, `.git/refs/heads/main`, `.git/objects/<sha>` и понять, **что там лежит**.
- Написать **GitHub Actions workflow**, который прогоняет тесты при PR и блокирует merge при failure.
- Если **запушил .env с боевым паролем** — знать playbook: rotate secret -> `git filter-repo` -> force push -> уведомить команду.

## Как читать курс

1. **По порядку.** Модули 03 (three trees) и 04 (branches) — это база, без которой rebase в модуле 07 не складывается в голове. Не перепрыгивайте.
2. **Параллельно с терминалом.** В каждом уроке есть командные блоки — запускайте их в **отдельном тестовом репо** (`git init test-repo`). Junior учится Git только пальцами, не глазами.
3. **Labs обязательны.** В конце ключевых модулей — lab с реалистичным DE-сценарием: ETL-проект с конфликтом в DAG, репо с накопившимся `.parquet`, rescue-история. Не пропускайте.
4. **Возвращайтесь в glossary / troubleshooting.** Когда в работе встретите «detached HEAD» или `non-fast-forward` — открывайте `data/troubleshooting.json` и читайте.

## Прерогативы Junior DE — много практики

Junior Data Engineer работает с Git **каждый день**: feature branch для нового airflow DAG, PR в dbt-репозиторий, rebase перед merge, разбор `git blame` чужой Python-функции. Этот курс осознанно перекошен в сторону практики:

- **~60% времени** — labs и упражнения на реальных DE-сценариях (Airflow DAGs, dbt models, Python ETL scripts, SQL миграции).
- **~30%** — концептуальное объяснение «что под капотом» (objects, refs, refspec, merge algorithm).
- **~10%** — теория VCS и workflow-философия.

Курс намеренно избегает «git за час» в стиле первых трёх команд. К концу вы поймёте, **почему `git pull` — это `fetch + merge`**, и почему в команде вашего работодателя, скорее всего, настроен `pull.rebase = true`.

## Технологии

- **Git 2.54+** (стабильная на май 2026)
- **GitHub** как primary хостинг (GitLab — упоминания в workflow-модуле)
- **GitHub Actions** для CI
- **pre-commit** framework (Python)
- **gitleaks**, **git-filter-repo**, **BFG Repo-Cleaner** для security-модуля
- **Git LFS** для больших файлов
- **OS:** macOS, Linux, Windows (через WSL2). Все примеры даны для bash/zsh.

## Структура репозитория

```
git-fundamentals/
├── config.json
├── README.md
├── data/
│   ├── glossary.json          # 60+ терминов
│   └── troubleshooting.json   # 25+ типичных проблем Junior DE
├── src/
│   ├── components/diagrams/   # Курс-специфичные React-визуализации
│   └── content/
│       ├── course/            # MDX уроки (модуль/урок)
│       └── quizzes/           # JSON квизы (per-lesson + _exam.json)
└── labs/                      # Hands-on labs с реалистичными DE-сценариями
```

## Автор

Lev Neganov — neganovlevs@gmail.com

## Лицензия

MIT
