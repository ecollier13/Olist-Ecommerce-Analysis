/* ============================================================
   OLIST ANALYSIS — DATA VALIDATION (Portfolio Version)
   Purpose:
     1) Sanity row counts + PK uniqueness
     2) Null completeness on key fields
     3) Referential integrity (orphan checks)
     4) Date ranges + sequence logic checks
     5) Domain checks (valid score ranges, non-negative money)
     6) Optional: persist a quality flag (guarded, rerunnable)

   Notes:
     - Core validation is READ-ONLY (SELECTs) so it’s safe to rerun.
     - Optional flag section is guarded to avoid “duplicate column” errors.
   ============================================================ */

USE olist_analysis;

SELECT DATABASE() AS current_database;

/* ============================================================
   1) ROW COUNTS (basic sanity)
   ============================================================ */
SELECT 'orders'        AS table_name, COUNT(*) AS num_rows FROM orders
UNION ALL SELECT 'order_items',    COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'customers',      COUNT(*) FROM customers
UNION ALL SELECT 'order_reviews',  COUNT(*) FROM order_reviews;


/* ============================================================
   2) PRIMARY KEY UNIQUENESS (should return 0 rows)
   ============================================================ */
-- orders: PK = order_id
SELECT order_id, COUNT(*) AS c
FROM orders
GROUP BY order_id
HAVING c > 1;

-- order_items: PK = (order_id, order_item_id)
SELECT order_id, order_item_id, COUNT(*) AS c
FROM order_items
GROUP BY order_id, order_item_id
HAVING c > 1;

-- order_payments: PK = (order_id, payment_sequential)
SELECT order_id, payment_sequential, COUNT(*) AS c
FROM order_payments
GROUP BY order_id, payment_sequential
HAVING c > 1;

-- customers: PK = customer_id
SELECT customer_id, COUNT(*) AS c
FROM customers
GROUP BY customer_id
HAVING c > 1;

-- order_reviews: PK = (review_id, order_id)
SELECT review_id, order_id, COUNT(*) AS c
FROM order_reviews
GROUP BY review_id, order_id
HAVING c > 1;


/* ============================================================
   3) NULL CHECKS (key fields)
   ============================================================ */
-- orders
SELECT
  SUM(order_id IS NULL)                 AS null_order_id,
  SUM(customer_id IS NULL)              AS null_customer_id,
  SUM(order_purchase_timestamp IS NULL)  AS null_purchase_ts
FROM orders;

-- order_items
SELECT
  SUM(order_id IS NULL)                 AS null_order_id,
  SUM(order_item_id IS NULL)            AS null_order_item_id,
  SUM(product_id IS NULL)               AS null_product_id,
  SUM(price IS NULL)                    AS null_price,
  SUM(freight_value IS NULL)            AS null_freight,
  SUM(shipping_limit_date IS NULL)      AS null_shipping_limit_date
FROM order_items;

-- order_payments
SELECT
  SUM(order_id IS NULL)                 AS null_order_id,
  SUM(payment_sequential IS NULL)       AS null_payment_sequential,
  SUM(payment_type IS NULL)             AS null_payment_type,
  SUM(payment_value IS NULL)            AS null_payment_value
FROM order_payments;

-- customers
SELECT
  SUM(customer_id IS NULL)              AS null_customer_id,
  SUM(customer_unique_id IS NULL)       AS null_customer_unique_id,
  SUM(customer_city IS NULL)            AS null_customer_city,
  SUM(customer_state IS NULL)           AS null_customer_state
FROM customers;

-- order_reviews
SELECT
  SUM(review_id IS NULL)                AS null_review_id,
  SUM(order_id IS NULL)                 AS null_order_id,
  SUM(review_score IS NULL)             AS null_review_score,
  SUM(review_creation_date IS NULL)     AS null_review_creation_date,
  SUM(review_answer_timestamp IS NULL)  AS null_review_answer_timestamp
FROM order_reviews;


/* ============================================================
   4) REFERENTIAL INTEGRITY (orphans)
   ============================================================ */
-- orders.customer_id must exist in customers
SELECT COUNT(*) AS missing_customers
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
WHERE o.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- order_items.order_id must exist in orders
SELECT COUNT(*) AS missing_orders_in_items
FROM order_items oi
LEFT JOIN orders o ON o.order_id = oi.order_id
WHERE oi.order_id IS NOT NULL
  AND o.order_id IS NULL;

-- order_payments.order_id must exist in orders
SELECT COUNT(*) AS missing_orders_in_payments
FROM order_payments op
LEFT JOIN orders o ON o.order_id = op.order_id
WHERE op.order_id IS NOT NULL
  AND o.order_id IS NULL;

-- order_reviews.order_id must exist in orders
SELECT COUNT(*) AS missing_orders_in_reviews
FROM order_reviews r
LEFT JOIN orders o ON o.order_id = r.order_id
WHERE r.order_id IS NOT NULL
  AND o.order_id IS NULL;


/* ============================================================
   5) DATE RANGES + NULLS (orders)
   ============================================================ */
SELECT
  MIN(order_purchase_timestamp)                 AS min_purchase,
  MAX(order_purchase_timestamp)                 AS max_purchase,
  SUM(order_purchase_timestamp IS NULL)         AS null_purchase,

  MIN(order_approved_at)                        AS min_approved,
  MAX(order_approved_at)                        AS max_approved,
  SUM(order_approved_at IS NULL)                AS null_approved,

  MIN(order_delivered_carrier_date)             AS min_carrier,
  MAX(order_delivered_carrier_date)             AS max_carrier,
  SUM(order_delivered_carrier_date IS NULL)     AS null_carrier,

  MIN(order_delivered_customer_date)            AS min_delivered,
  MAX(order_delivered_customer_date)            AS max_delivered,
  SUM(order_delivered_customer_date IS NULL)    AS null_delivered,

  MIN(order_estimated_delivery_date)            AS min_estimated,
  MAX(order_estimated_delivery_date)            AS max_estimated,
  SUM(order_estimated_delivery_date IS NULL)    AS null_estimated
FROM orders;


/* ============================================================
   6) DATE SEQUENCE LOGIC (orders)
   Rule (when values exist):
     purchase <= approved <= carrier <= delivered_customer
   Output:
     - total bad sequences (count)
     - breakdown by type
     - sample rows for inspection
   ============================================================ */

-- Total bad sequences
SELECT COUNT(*) AS bad_sequences
FROM orders
WHERE
  (order_approved_at IS NOT NULL
   AND order_purchase_timestamp IS NOT NULL
   AND order_purchase_timestamp > order_approved_at)
  OR
  (order_delivered_carrier_date IS NOT NULL
   AND order_approved_at IS NOT NULL
   AND order_approved_at > order_delivered_carrier_date)
  OR
  (order_delivered_customer_date IS NOT NULL
   AND order_delivered_carrier_date IS NOT NULL
   AND order_delivered_carrier_date > order_delivered_customer_date);

-- Breakdown by anomaly type
SELECT
  SUM(order_approved_at IS NOT NULL
      AND order_purchase_timestamp IS NOT NULL
      AND order_purchase_timestamp > order_approved_at) AS purchase_after_approved,

  SUM(order_delivered_carrier_date IS NOT NULL
      AND order_approved_at IS NOT NULL
      AND order_approved_at > order_delivered_carrier_date) AS approved_after_carrier,

  SUM(order_delivered_customer_date IS NOT NULL
      AND order_delivered_carrier_date IS NOT NULL
      AND order_delivered_carrier_date > order_delivered_customer_date) AS carrier_after_delivered
FROM orders;

-- Sample rows (inspect what "bad" looks like)
SELECT
  order_id,
  order_status,
  order_purchase_timestamp,
  order_approved_at,
  order_delivered_carrier_date,
  order_delivered_customer_date
FROM orders
WHERE
  (order_approved_at IS NOT NULL
   AND order_purchase_timestamp IS NOT NULL
   AND order_purchase_timestamp > order_approved_at)
  OR
  (order_delivered_carrier_date IS NOT NULL
   AND order_approved_at IS NOT NULL
   AND order_approved_at > order_delivered_carrier_date)
  OR
  (order_delivered_customer_date IS NOT NULL
   AND order_delivered_carrier_date IS NOT NULL
   AND order_delivered_carrier_date > order_delivered_customer_date)
LIMIT 25;


/* ============================================================
   7) SHIPPING LIMIT DATE CHECKS (order_items)
   ============================================================ */
SELECT
  COUNT(*) AS total_rows,
  SUM(shipping_limit_date IS NULL) AS null_shipping_limit,
  MIN(shipping_limit_date) AS min_shipping_limit,
  MAX(shipping_limit_date) AS max_shipping_limit
FROM order_items;

-- shipping_limit_date should not be before purchase timestamp (sanity check)
SELECT COUNT(*) AS bad_shipping_dates
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE oi.shipping_limit_date IS NOT NULL
  AND o.order_purchase_timestamp IS NOT NULL
  AND oi.shipping_limit_date < o.order_purchase_timestamp;

-- Sample bad shipping rows (if any)
SELECT
  oi.order_id,
  o.order_purchase_timestamp,
  oi.shipping_limit_date
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE oi.shipping_limit_date IS NOT NULL
  AND o.order_purchase_timestamp IS NOT NULL
  AND oi.shipping_limit_date < o.order_purchase_timestamp
LIMIT 25;


/* ============================================================
   8) REVIEW DATE CHECKS (order_reviews)
   ============================================================ */
SELECT
  COUNT(*) AS total_rows,
  SUM(review_creation_date IS NULL)     AS null_review_created,
  SUM(review_answer_timestamp IS NULL)  AS null_review_answered,
  MIN(review_creation_date)             AS min_review_created,
  MAX(review_creation_date)             AS max_review_created,
  MIN(review_answer_timestamp)          AS min_review_answered,
  MAX(review_answer_timestamp)          AS max_review_answered
FROM order_reviews;

-- answer timestamp should not be earlier than creation date
SELECT COUNT(*) AS bad_review_sequence
FROM order_reviews
WHERE review_creation_date IS NOT NULL
  AND review_answer_timestamp IS NOT NULL
  AND review_answer_timestamp < review_creation_date;

-- Sample bad review rows (if any)
SELECT
  review_id,
  order_id,
  review_creation_date,
  review_answer_timestamp
FROM order_reviews
WHERE review_creation_date IS NOT NULL
  AND review_answer_timestamp IS NOT NULL
  AND review_answer_timestamp < review_creation_date
LIMIT 25;


/* ============================================================
   9) DOMAIN CHECKS (high-value sanity)
   ============================================================ */
-- review_score expected 1–5 (and in your dataset it should be non-null)
SELECT COUNT(*) AS invalid_review_scores
FROM order_reviews
WHERE review_score IS NULL
   OR review_score NOT BETWEEN 1 AND 5;

-- negative money values should not exist
SELECT COUNT(*) AS negative_prices_or_freight
FROM order_items
WHERE price < 0 OR freight_value < 0;

SELECT COUNT(*) AS negative_payments
FROM order_payments
WHERE payment_value < 0;


/* ============================================================
   10) OPTIONAL: PERSIST A QUALITY FLAG 
   Why:
     - Useful for later analysis / filtering without rewriting logic.
   Trade-off:
     - This mutates schema/data, so keep it optional.
   ============================================================ */

-- (A) Add flag column only if it doesn't already exist
SET @col_exists :=
(
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'orders'
    AND column_name = 'has_bad_sequence'
);

SET @sql := IF(
  @col_exists = 0,
  'ALTER TABLE orders ADD COLUMN has_bad_sequence TINYINT(1) NOT NULL DEFAULT 0;',
  'SELECT ''has_bad_sequence already exists'' AS info;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- (B) Populate flag (safe to rerun)
UPDATE orders
SET has_bad_sequence =
  CASE
    WHEN
      (order_approved_at IS NOT NULL
       AND order_purchase_timestamp IS NOT NULL
       AND order_purchase_timestamp > order_approved_at)
      OR
      (order_delivered_carrier_date IS NOT NULL
       AND order_approved_at IS NOT NULL
       AND order_approved_at > order_delivered_carrier_date)
      OR
      (order_delivered_customer_date IS NOT NULL
       AND order_delivered_carrier_date IS NOT NULL
       AND order_delivered_carrier_date > order_delivered_customer_date)
    THEN 1
    ELSE 0
  END;

-- (C) Flag summary
SELECT
  SUM(has_bad_sequence = 1) AS flagged_orders,
  COUNT(*)                  AS total_orders
FROM orders;
