# Подсказки для LAB-02

Открой этот файл только если потратил минимум 20 минут на самостоятельную попытку. Здесь только команды — без объяснений логики (это README сам должен покрыть).

## Шаг 1. Interactive rebase

Открыть редактор интерактивного rebase для последних 3 коммитов:

```bash
git rebase -i HEAD~3
```

Сменить редактор по умолчанию (если vim непривычен):

```bash
git config --global core.editor "nano"
# или
git config --global core.editor "code --wait"
```

В редакторе rebase todo-листа замени `pick` на:

- `reword` — оставить коммит, дать переписать сообщение.
- `squash` — склеить с предыдущим, сообщения объединить.
- `fixup` — склеить с предыдущим, сообщение этого коммита выкинуть.
- `drop` — выкинуть коммит полностью.

## Шаг 2. Rebase на main

```bash
git fetch origin       # (опционально, обновить ссылки на origin)
git rebase main
```

## Шаг 3. Разрешить конфликт

Посмотреть, какие файлы в конфликте:

```bash
git status
```

Посмотреть, что именно конфликтует:

```bash
git diff
```

После того как поправил файл — пометить разрешённым:

```bash
git add src/etl.py
git rebase --continue
```

Если хочешь отменить:

```bash
git rebase --abort
```

Использовать сторону при разрешении (только если уверен, что одна сторона правильная):

```bash
git checkout --ours src/etl.py    # взять версию main (на которую ребейзимся)
git checkout --theirs src/etl.py  # взять версию feature (твою)
```

Внимание: в rebase `ours` и `theirs` **меняются местами** относительно merge. В rebase `ours` — это та ветка, поверх которой ребейзимся (то есть main).

## Шаг 4. Force push

```bash
git push --force-with-lease origin feature/etl-loader
```

Если git ругается на `cannot lock ref` или `stale info`:

```bash
git fetch origin
git push --force-with-lease origin feature/etl-loader
```

## Reflog: восстановление после ошибок

Посмотреть всю историю движений HEAD:

```bash
git reflog
```

Вернуться к состоянию N шагов назад:

```bash
git reset --hard HEAD@{5}
```

Полный сброс лабы:

```bash
bash setup.sh ~/de-projects/lab02-rebase
```

## Полезные команды для проверки

Граф истории всех веток:

```bash
git log --oneline --graph --all --decorate
```

Сколько коммитов feature ушло вперёд от main:

```bash
git rev-list --count main..feature/etl-loader
```

Точка разветвления:

```bash
git merge-base main feature/etl-loader
```

Сравнить с верхушкой main:

```bash
git rev-parse main
```

Если merge-base равен main HEAD — значит ты успешно отребейзил.
