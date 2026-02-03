/* ============================================================
   OLIST E-COMMERCE ANALYSIS
   Purpose:
   Answer core business questions related to:
   - Growth
   - Delivery performance
   - Customer satisfaction
   - Payment behavior

   All analysis uses delivered orders unless stated otherwise.
   ============================================================ */

USE olist_analysis;

/* ============================================================
   Q1 & Q2
   How has order volume and revenue changed over time?
   Are customers placing higher-value orders over time?
   ============================================================ */

WITH order_revenue AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_revenue
    FROM order_payments
    GROUP BY order_id
)
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(DISTINCT o.order_id) AS num_orders,
    ROUND(SUM(r.order_revenue), 2) AS total_revenue,
    ROUND(SUM(r.order_revenue) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
LEFT JOIN order_revenue r
    ON r.order_id = o.order_id
GROUP BY purchase_month
ORDER BY purchase_month;



/* ============================================================
   Q3
   How long does delivery usually take,
   and has this changed over time?
   ============================================================ */

-- Overall delivery duration
SELECT
    COUNT(*) AS total_orders,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 2) AS avg_delivery_days,
    MIN(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)) AS min_delivery_days,
    MAX(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)) AS max_delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL;

-- Delivery trend over time
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(*) AS num_orders,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 2) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
GROUP BY purchase_month
ORDER BY purchase_month;



/* ============================================================
   Q4
   How often are orders delivered late?
   ============================================================ */

WITH delivery_status AS (
    SELECT
        order_id,
        DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) AS days_delay
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)
SELECT
    CASE
        WHEN days_delay <= -1 THEN 'Early'
        WHEN days_delay = 0 THEN 'On time'
        WHEN days_delay BETWEEN 1 AND 3 THEN '1–3 days late'
        WHEN days_delay BETWEEN 4 AND 7 THEN '4–7 days late'
        ELSE '8+ days late'
    END AS delay_bucket,
    COUNT(*) AS num_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders
FROM delivery_status
GROUP BY delay_bucket
ORDER BY
    CASE delay_bucket
        WHEN 'Early' THEN 1
        WHEN 'On time' THEN 2
        WHEN '1–3 days late' THEN 3
        WHEN '4–7 days late' THEN 4
        ELSE 5
    END;



/* ============================================================
   Q5
   How do customer review scores trend over time?
   ============================================================ */

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(*) AS num_reviews,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM orders o
JOIN order_reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL
  AND r.review_score IS NOT NULL
GROUP BY purchase_month
ORDER BY purchase_month;



/* ============================================================
   Q6
   Is late delivery associated with lower review scores?
   ============================================================ */

WITH delay_reviews AS (
    SELECT
        o.order_id,
        r.review_score,
        DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS days_delay
    FROM orders o
    JOIN order_reviews r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)
SELECT
    CASE
        WHEN days_delay <= -1 THEN 'Early'
        WHEN days_delay = 0 THEN 'On time'
        WHEN days_delay BETWEEN 1 AND 3 THEN '1–3 days late'
        WHEN days_delay BETWEEN 4 AND 7 THEN '4–7 days late'
        ELSE '8+ days late'
    END AS delay_bucket,
    COUNT(*) AS num_orders,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    ROUND(SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*), 2) AS low_review_pct
FROM delay_reviews
GROUP BY delay_bucket
ORDER BY
    CASE delay_bucket
        WHEN 'Early' THEN 1
        WHEN 'On time' THEN 2
        WHEN '1–3 days late' THEN 3
        WHEN '4–7 days late' THEN 4
        ELSE 5
    END;



/* ============================================================
   Q7
   Which payment methods are most commonly used?
   ============================================================ */

SELECT
    p.payment_type,
    COUNT(*) AS num_payments,
    ROUND(SUM(p.payment_value), 2) AS total_payment_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS payment_share_pct
FROM orders o
JOIN order_payments p
    ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.payment_type
ORDER BY num_payments DESC;



/* ============================================================
   Q8
   Do installment payments correlate with higher order values?
   ============================================================ */

WITH order_payment_summary AS (
    SELECT
        o.order_id,
        SUM(p.payment_value) AS order_value,
        MAX(p.payment_installments) AS max_installments
    FROM orders o
    JOIN order_payments p
        ON p.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id
)
SELECT
    CASE
        WHEN max_installments = 1 THEN '1 installment'
        WHEN max_installments BETWEEN 2 AND 3 THEN '2–3 installments'
        WHEN max_installments BETWEEN 4 AND 6 THEN '4–6 installments'
        WHEN max_installments BETWEEN 7 AND 12 THEN '7–12 installments'
        ELSE '13+ installments'
    END AS installment_bucket,
    COUNT(*) AS num_orders,
    ROUND(AVG(order_value), 2) AS avg_order_value
FROM order_payment_summary
GROUP BY installment_bucket
ORDER BY
    CASE installment_bucket
        WHEN '1 installment' THEN 1
        WHEN '2–3 installments' THEN 2
        WHEN '4–6 installments' THEN 3
        WHEN '7–12 installments' THEN 4
        ELSE 5
    END;
