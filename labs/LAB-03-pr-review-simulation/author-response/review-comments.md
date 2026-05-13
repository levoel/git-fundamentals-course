# Review comments on your PR

Тимлид (Анна) оставила 4 комментария на твой `compute_retention.py`. Прочитай их внимательно, потом напиши ответ в `my-response.md`.

---

## Comment 1 — Анна, 09:42

### blocker: SQL injection via f-string

**File:** `my_code.py:L21`

`query = f"""... INTERVAL '{months} months' ..."""` — это f-string подставляет значение прямо в SQL текст. Если кто-то вызовет `compute_retention(engine, months="12; DROP TABLE fct_orders;--")`, мы получим классический SQL injection.

Даже если этот параметр сейчас приходит только от внутреннего кода — это сломанный паттерн, который рано или поздно укусит. Используй параметризацию (`pd.read_sql(query, engine, params={"months": months})` + `INTERVAL :months MONTHS` или эквивалент в твоём диалекте).

---

## Comment 2 — Анна, 09:48

### blocker: hardcoded credentials in __main__

**File:** `my_code.py:L73`

```python
eng = create_engine("postgresql://user:password@localhost:5432/warehouse")
```

Это пароль в коде, который попадёт в git history навсегда. Даже если это «test password» — gitleaks такое поймает, и придётся git-filter-repo делать. Используй переменные окружения:

```python
import os
eng = create_engine(os.environ["WAREHOUSE_DSN"])
```

И добавь пример в `.env.example`.

---

## Comment 3 — Анна, 09:51

### nit: prefer pathlib over string paths

**File:** `my_code.py:L65`

`save_to_csv(result, "/tmp/retention.csv")` — лучше использовать `pathlib.Path`. У нас в репо принято `from pathlib import Path`, см. `dags/orders_etl.py`.

Не блокирующее.

---

## Comment 4 — Анна, 09:55

### question: why pandas instead of pure SQL?

**File:** `my_code.py:L57-L60`

Вычисление retention rate можно сделать целиком на SQL уровне (через `LAG` или self-join по cohort_month). Зачем выгружать всё в pandas и считать на стороне Python? На полных данных это может быть медленнее и потреблять много памяти.

Хочется понять мотивацию — может, я что-то упускаю.

---

## Что от тебя ожидается

В `my-response.md` ответь на каждый комментарий — по одному параграфу. Используй теги (см. `response-template.md`):

- `agree` — согласен, фикшу.
- `discuss` — нужно обсудить.
- `push back` — не согласен.

Не молчи ни на один комментарий — каждый должен получить ответ.
