{{
  config(
    materialized='table'
  )
}}

-- fct_customer_orders: aggregates order totals per customer.
-- Used by Marketing retention dashboard.

WITH orders AS (

    SELECT *
    FROM {{ ref('stg_orders') }}
    WHERE order_date >= '2024-01-01'

),

customers AS (

    SELECT userid AS customer_id, email, signup_date
    FROM {{ ref('stg_customers') }}

),

joined AS (

    SELECT
        c.customer_id,
        c.email,
        c.signup_date,
        o.order_id,
        o.user_id,
        o.order_date,
        o.amount
    FROM orders o
    LEFT JOIN customers c ON o.user_id = c.customer_id

),

aggregated AS (

    SELECT
        customer_id,
        COUNT(order_id) AS total_orders,
        SUM(amount) AS total_revenue,
        SUM(amount) * 0.15 AS estimated_profit,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date
    FROM joined
    GROUP BY customer_id

)

SELECT * FROM aggregated
