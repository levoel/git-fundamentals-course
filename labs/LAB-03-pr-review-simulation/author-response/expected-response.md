# Expected response

Это пример, как мог бы выглядеть твой ответ на review Анны. Твои формулировки могут отличаться — важна структура: каждый комментарий получил ответ, теги расставлены корректно, push back содержит факт.

---

## Re: Comment 1 — SQL injection via f-string

### agree

Согласен полностью, проглядел. f-string в SQL — однозначный антипаттерн, даже на «внутреннем» параметре. Сейчас перепишу на параметризованный запрос:

```python
from sqlalchemy import text

query = text("""
    ...
    WHERE signup_date >= CURRENT_DATE - make_interval(months => :months)
    ...
""")
df = pd.read_sql(query, engine, params={"months": months})
```

Заодно добавлю валидацию: `if not isinstance(months, int) or months < 1: raise ValueError`.

Fix зальётся следующим коммитом.

---

## Re: Comment 2 — hardcoded credentials

### agree

Признаю, это `__main__` для локального теста, и пароль фиктивный — но мысль правильная, gitleaks такое поймает и будет лишний раз шуметь. Заменю на:

```python
import os

dsn = os.environ.get("WAREHOUSE_DSN")
if not dsn:
    raise RuntimeError("WAREHOUSE_DSN env var is required")
eng = create_engine(dsn)
```

Создам `.env.example` с `WAREHOUSE_DSN=postgresql://user:password@localhost:5432/warehouse` для документации.

Fix зальётся тем же коммитом, что и SQL injection (одна тема — secrets/safety).

---

## Re: Comment 3 — pathlib over string paths

### agree

Окей, обновлю до `pathlib.Path`. Спасибо за ссылку на `dags/orders_etl.py` — посмотрел, действительно консистентный стиль.

Заодно сделаю `path: Path = Path("/tmp/retention.csv")` параметром функции, а не хардкод.

---

## Re: Comment 4 — why pandas instead of pure SQL

### push back

Спасибо за вопрос, действительно стоит зафиксировать причину в коде. Pandas здесь использован осознанно — вычисление `retention_rate` нормализуется на per-cohort baseline (`active_users / base`).

На SQL это требует self-join или `LAG/FIRST_VALUE OVER (PARTITION BY cohort_month ORDER BY period_months)`. Замерил на staging-датасете:

- 12 cohorts × 12 periods (144 строки): SQL window 180ms, pandas 80ms.
- Расход памяти pandas: ~5KB на dataframe.

Объём данных микроскопический, потому что мы агрегируем заранее в `cohort_activity` CTE — на выход идёт ≤ months × months строк (144 при дефолте). Pandas-версия читабельнее и тестируется без БД (mock `pd.read_sql`).

Готов перевести в SQL, если:

- Появится требование выгружать сырые данные без агрегации (тогда объём вырастет на порядки).
- Marketing запросит большее число cohorts (500+) — тогда self-join действительно будет узким местом.

Зафиксирую этот аргумент комментарием в коде:

```python
# Retention rate normalized in pandas:
# - aggregation already done in SQL (cohort_activity CTE), so dataframe is small (~months^2 rows)
# - keeps the function testable without a live DB (mock pd.read_sql)
```

Если есть кейс в голове, где pandas не справится — давай обсудим, могу заранее переделать.

---

## Чему стоит научиться по этому примеру

1. **На два blocker-а реакция = agree, без аргументации.** Это правильно — оба комментария указывают на однозначные проблемы. Спорить здесь бессмысленно и вредно.

2. **На nit реакция = agree.** Можно было бы push back («это `/tmp/retention.csv`, какая разница»), но nit-ы дешёво фиксить, и спор по мелочам тратит время команды.

3. **На question — push back с фактами.** Здесь важно показать, что ты подумал об альтернативе, померил, и принял осознанное решение. Reviewer не настаивает («хочется понять мотивацию») — значит, обоснованный ответ закроет вопрос.

4. **Push back ВСЕГДА с компромиссом.** «Готов переделать, если...» — это не слабость, это профессионализм. Reviewer видит, что ты не уперся, а аргументируешь.

5. **Не молчи.** В этом примере на все 4 комментария есть ответ. Если хотя бы один без ответа — review-сессия становится «открытой», PR не мержится, у тимлида растёт фрустрация.

## Антипример

Как не надо ответить:

> Comment 1: ok
> Comment 2: ok
> Comment 3: ok
> Comment 4: я не понял вопрос

Что плохо:

- Никаких деталей, что именно фиксишь.
- Нет коммитов с фиксами.
- На вопрос — отшучивание вместо аргумента.

С таким ответом review застрянет, и тимлид потратит ещё 30 минут на повторный round.
