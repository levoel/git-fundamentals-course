# Expected PR — что должно получиться

Эта папка содержит reference materials для проверки твоей работы в LAB-04.

## Files

| File | Описание |
|---|---|
| `PR_BODY.md` | Пример тела PR (что вставлять в gh pr create --body) |
| `REVIEW_COMMENTS.md` | 5 review comments + expected reactions |
| `user_events_dag.py` | Финальная версия DAG (после всех review fixes) |
| `test_user_events.py` | 3 теста, которые должны быть зелёными |
| `dags_README_addition.md` | Что добавить в dags/README.md |

## Когда смотреть

**НЕ открывай эти файлы перед собственной попыткой!** Сначала прочитай LAB README, попробуй реализовать сам. Reference materials — для self-check после.

Используй reference:
1. Если застрял на implementation — посмотри `user_events_dag.py` как template (но напиши свою версию по памяти, не copy-paste).
2. После завершения — diff свою версию с reference, найди differences.
3. После handling review comments — сравни response style.

## Self-check после lab

После завершения lab:

1. **DAG файл**:
   - Variable.get() для stage? [x]
   - timedelta для retry_delay? [x]
   - Tables written в docstring? [x]
   - Conventional commits с DE-1234 ref? [x]

2. **Tests** все 3 passing локально?

3. **README.md** обновлён?

4. **PR body** содержит Summary, Changes, Testing, Acceptance Criteria, Reviewer Notes?

5. **Review responses** в правильном style (acknowledge + commit SHA + reasoning)?

6. **Conflict resolution** в snowflake_loaders.py — semantic, не mechanical?

7. **Force push** через `--force-with-lease`?

8. **Cleanup** после merge — local branch + remote pruned?

9. **Hotfix flow** за 5 минут?

Если 9/9 [x] — capstone successfully completed.

## Reflection prompt

После lab напиши себе короткие answers:

1. Что было самое сложное?
2. Что узнал новое (даже после прохождения всех 20 модулей)?
3. Какой next step для real-world practice?

Это feedback для самого себя — храни в Notion / Obsidian / wherever.
