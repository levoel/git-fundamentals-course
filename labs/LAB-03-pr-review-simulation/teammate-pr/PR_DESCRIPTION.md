# PR #142: feat: add fct_customer_orders dbt model

**Author:** Максим К. (data-analytics team)
**Base:** `main` ← **Head:** `feat/fct-customer-orders`
**Reviewers:** @data-eng-juniors

## What

Adds a new fact table `fct_customer_orders` that aggregates order totals per customer. Will be used by the Marketing team for their retention dashboard.

## Why

Marketing запросили дашборд по retention. Сейчас они джойнят `stg_orders` напрямую в Looker, это медленно и каждый раз выгребается весь дамп. Будем pre-aggregate в dbt — один раз в день, потом дашборд читает уже агрегат.

## How

- New `models/fct_customer_orders.sql` — aggregates by `customer_id`, computes total orders count, total revenue, first/last order dates.
- Updated `schema.yml` — added column descriptions.
- Tests: пока добавил basic `not_null` на customer_id.

## Test plan

- [x] `dbt run --models fct_customer_orders` runs locally without errors.
- [x] Looks reasonable on prod sample (manually compared 5 customers to raw orders).
- [ ] Performance tested on full prod data — TBD.
- [ ] Marketing review — TBD, after merge.

## Notes

Это мой первый dbt PR, так что review welcome. Если есть лучший способ — скажите!
