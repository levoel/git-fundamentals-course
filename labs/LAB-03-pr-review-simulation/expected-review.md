# Expected review для PR #142: feat: add fct_customer_orders

В этом PR 5 проблем — 2 blocker, 2 nit, 1 question. Это пример хорошего review. Твои формулировки могут отличаться, но проблемы должны быть найдены.

---

## blocker: hardcoded date breaks backfills

**File:** `models/fct_customer_orders.sql:L12`

В WHERE клаусе зашита `'2024-01-01'`. При backfill за более ранний период данные будут молча обрезаться, что приведёт к неверному `first_order_date` для исторических клиентов. Это особенно опасно, потому что Marketing будет считать retention — и метрика поедет.

**Suggested fix:** вынести в dbt-переменную:

```sql
WHERE order_date >= '{{ var("orders_start_date", "2024-01-01") }}'
```

И добавить `vars: orders_start_date: '2024-01-01'` в `dbt_project.yml`. Тогда backfill можно делать через `dbt run --vars '{orders_start_date: "2020-01-01"}'`.

---

## blocker: magic number 0.15 without justification

**File:** `models/fct_customer_orders.sql:L41`

`estimated_profit = total_revenue * 0.15` — откуда взялось 0.15? Это маржинальность? Если да, она зависит от категории товара, периода, акций. Маркетинг будет принимать решения на основе этой цифры — лучше либо:

1. Удалить колонку и считать profit отдельно в Looker (с правильной разбивкой), либо
2. Завести `{{ var("estimated_margin_pct") }}` и оставить комментарий: «маржа 0.15 согласована с finance на 2024 Q1, ревью каждый квартал».

Текущее состояние = тихий риск, на ровном месте подложит метрику.

---

## nit: inconsistent column naming (userid vs customer_id)

**File:** `models/fct_customer_orders.sql:L19`

В `stg_customers` колонка называется `userid` (без подчёркивания), но в этом PR она используется через alias `customer_id`. В `stg_orders` (`o.user_id`) — с подчёркиванием. Если эта inconsistency пришла из upstream — пожалуйста, открой follow-up issue, чтобы переименовать `userid` -> `user_id` в `stg_customers`. Так избежим путаницы при дебаге.

**Suggested fix:** добавить TODO в код и issue в трекере.

---

## nit: SELECT * in CTE pulls unused columns

**File:** `models/fct_customer_orders.sql:L11`

`SELECT *` из `stg_orders` подтягивает все колонки, из которых дальше используются `order_id`, `user_id`, `order_date`, `amount`. На больших объёмах это лишний shuffle и расход памяти. Современные query planner-ы это часто оптимизируют, но не всегда — особенно на BigQuery со столбцами `JSON`.

**Suggested fix:**

```sql
SELECT order_id, user_id, order_date, amount
FROM {{ ref('stg_orders') }}
```

---

## question: should we have a unique test on customer_id?

**File:** `schema.yml`

Сейчас на `customer_id` есть только `not_null`. Но по логике в `fct_customer_orders` каждый customer должен встречаться **ровно один раз** (GROUP BY customer_id). Если в `stg_customers` случайно появится дубликат — JOIN раздует таблицу, и эта инвариантa сломается тихо.

Имеет смысл добавить `unique` test:

```yaml
- name: customer_id
  tests:
    - not_null
    - unique
```

Какие были соображения не добавлять? Может быть, ожидается, что customer_id будет дублироваться в каких-то edge cases?

---

## Подсчёт

| Тег | Кол-во | Что в этом PR |
|---|---|---|
| blocker | 2 | hardcoded date, magic 0.15 |
| nit | 2 | userid naming, SELECT * |
| question | 1 | missing unique test |

Итого **5 комментариев**.

## На что ещё можно было бы обратить внимание (не входит в основные 5)

- **JOIN направление подозрительный.** `orders LEFT JOIN customers` — если у нас «cusomter без orders», он не попадёт. Если у нас «order с битым user_id» — `customer_id` будет NULL и попадёт в GROUP BY как одна строка с NULL. Возможно, нужен `INNER JOIN`.
- **`materialized='table'`** — для marketing-дашборда может быть лучше `incremental` (если данные большие).
- **`first_order_date` зависит от фильтра `>= '2024-01-01'`.** Если customer сделал первый заказ в 2023, его «первый заказ» в фактовой таблице будет неверным. Связано с blocker #1.
- **Нет тестов на свежесть данных** (`dbt source freshness`).
- **Описание PR говорит «Performance tested on full prod data — TBD».** Это нужно сделать до merge, на больших таблицах ленивый JOIN может убить кластер.

Эти пункты — для опытных reviewer-ов. Junior, который нашёл 5 основных проблем — уже большой молодец.

## Пример того, как НЕ надо

Сравни с этим (плохой review):

> «Слишком много проблем. Hardcoded date — фу. SELECT * — фу. Где tests? Перепиши.»

Что плохо:

- Не указан файл и строка.
- Нет приоритезации (что blocker, что nit).
- «Перепиши» — без вектора.
- Эмоциональная окраска («фу»).
- Автор не поймёт, что фиксить в первую очередь.

Хороший review — это **техническое задание для автора**, а не ругательное письмо.
