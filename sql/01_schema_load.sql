/* ============================================================
   OLIST ANALYSIS — Clean Load + Typed Dates + Clean Schema
   Source CSV format confirmed: M/D/YYYY H:MM (24-hour clock)
   Example: 10/2/2017 10:56, 10/18/2017 0:00
   ============================================================ */

-- 0) Create + select database
CREATE DATABASE IF NOT EXISTS olist_analysis;
USE olist_analysis;

-- 1) Enable local infile (needed for LOAD DATA LOCAL INFILE)
SET GLOBAL local_infile = 1;
SET SESSION local_infile = 1;

/* If your CSV uses Windows line endings and you get weird row loads,
   change LINES TERMINATED BY '\n' to '\r\n'. */


/* ============================================================
   TABLE: orders
   ============================================================ */
DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
  order_id VARCHAR(50) NOT NULL,
  customer_id VARCHAR(50),
  order_status VARCHAR(20),

  order_purchase_timestamp DATETIME NULL,
  order_approved_at DATETIME NULL,
  order_delivered_carrier_date DATETIME NULL,
  order_delivered_customer_date DATETIME NULL,
  order_estimated_delivery_date DATETIME NULL,

  CONSTRAINT pk_orders PRIMARY KEY (order_id),
  INDEX idx_orders_customer (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA LOCAL INFILE 'C:/Users/lenovo/Documents/Project 3/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, customer_id, order_status,
 @purchase, @approved, @carrier, @delivered, @estimated)
SET
order_purchase_timestamp =
  CASE
    WHEN NULLIF(TRIM(REPLACE(@purchase, '\r','')), '') IS NULL THEN NULL
    WHEN TRIM(@purchase) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
      THEN STR_TO_DATE(TRIM(REPLACE(@purchase, '\r','')), '%Y-%m-%d %H:%i:%s')
    ELSE STR_TO_DATE(TRIM(REPLACE(@purchase, '\r','')), '%c/%e/%Y %H:%i')
  END,

order_approved_at =
  CASE
    WHEN NULLIF(TRIM(REPLACE(@approved, '\r','')), '') IS NULL THEN NULL
    WHEN TRIM(@approved) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
      THEN STR_TO_DATE(TRIM(REPLACE(@approved, '\r','')), '%Y-%m-%d %H:%i:%s')
    ELSE STR_TO_DATE(TRIM(REPLACE(@approved, '\r','')), '%c/%e/%Y %H:%i')
  END,

order_delivered_carrier_date =
  CASE
    WHEN NULLIF(TRIM(REPLACE(@carrier, '\r','')), '') IS NULL THEN NULL
    WHEN TRIM(@carrier) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
      THEN STR_TO_DATE(TRIM(REPLACE(@carrier, '\r','')), '%Y-%m-%d %H:%i:%s')
    ELSE STR_TO_DATE(TRIM(REPLACE(@carrier, '\r','')), '%c/%e/%Y %H:%i')
  END,

order_delivered_customer_date =
  CASE
    WHEN NULLIF(TRIM(REPLACE(@delivered, '\r','')), '') IS NULL THEN NULL
    WHEN TRIM(@delivered) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
      THEN STR_TO_DATE(TRIM(REPLACE(@delivered, '\r','')), '%Y-%m-%d %H:%i:%s')
    ELSE STR_TO_DATE(TRIM(REPLACE(@delivered, '\r','')), '%c/%e/%Y %H:%i')
  END,

order_estimated_delivery_date =
  CASE
    WHEN NULLIF(TRIM(REPLACE(@estimated, '\r','')), '') IS NULL THEN NULL
    WHEN TRIM(@estimated) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
      THEN STR_TO_DATE(TRIM(REPLACE(@estimated, '\r','')), '%Y-%m-%d %H:%i:%s')
    ELSE STR_TO_DATE(TRIM(REPLACE(@estimated, '\r','')), '%c/%e/%Y %H:%i')
  END;


/* ============================================================
   TABLE: customers
   ============================================================ */
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
  customer_id VARCHAR(50) NOT NULL,
  customer_unique_id VARCHAR(50),
  customer_zip_code_prefix VARCHAR(10),
  customer_city VARCHAR(100),
  customer_state VARCHAR(10),

  CONSTRAINT pk_customers PRIMARY KEY (customer_id),
  INDEX idx_customers_unique (customer_unique_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA LOCAL INFILE 'C:/Users/lenovo/Documents/Project 3/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


/* ============================================================
   TABLE: order_items
   ============================================================ */
DROP TABLE IF EXISTS order_items;

CREATE TABLE order_items (
  order_id VARCHAR(50) NOT NULL,
  order_item_id INT NOT NULL,
  product_id VARCHAR(50),
  seller_id VARCHAR(50),

  shipping_limit_date DATETIME NULL,
  price DECIMAL(10,2),
  freight_value DECIMAL(10,2),

  CONSTRAINT pk_order_items PRIMARY KEY (order_id, order_item_id),
  INDEX idx_order_items_order (order_id),
  INDEX idx_order_items_product (product_id),
  INDEX idx_order_items_seller (seller_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA LOCAL INFILE 'C:/Users/lenovo/Documents/Project 3/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, order_item_id, product_id, seller_id,
 @shipping_limit_date_raw, price, freight_value)
SET
shipping_limit_date =
  CASE
    WHEN NULLIF(TRIM(REPLACE(@shipping_limit_date_raw, '\r','')), '') IS NULL THEN NULL
    ELSE STR_TO_DATE(TRIM(REPLACE(@shipping_limit_date_raw, '\r','')), '%c/%e/%Y %H:%i')
  END;


/* ============================================================
   TABLE: order_payments
   ============================================================ */
DROP TABLE IF EXISTS order_payments;

CREATE TABLE order_payments (
  order_id VARCHAR(50) NOT NULL,
  payment_sequential INT NOT NULL,
  payment_type VARCHAR(30),
  payment_installments INT,
  payment_value DECIMAL(10,2),

  CONSTRAINT pk_order_payments PRIMARY KEY (order_id, payment_sequential),
  INDEX idx_order_payments_order (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA LOCAL INFILE 'C:/Users/lenovo/Documents/Project 3/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


/* ============================================================
   TABLE: order_reviews
   Notes: the dataset includes AM/PM timestamps in some fields.
   ============================================================ */
DROP TABLE IF EXISTS order_reviews;

CREATE TABLE order_reviews (
  review_id VARCHAR(50) NOT NULL,
  order_id VARCHAR(50) NOT NULL,

  review_score TINYINT,
  review_comment_title TEXT,
  review_comment_message TEXT,

  review_creation_date DATETIME NULL,
  review_answer_timestamp DATETIME NULL,

  CONSTRAINT pk_order_reviews PRIMARY KEY (review_id, order_id),
  INDEX idx_order_reviews_order (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA LOCAL INFILE 'C:/Users/lenovo/Documents/Project 3/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(review_id, order_id, review_score,
 review_comment_title, review_comment_message,
 @review_creation_date_raw, @review_answer_timestamp_raw)
SET
review_creation_date =
  CASE
    WHEN NULLIF(TRIM(REPLACE(@review_creation_date_raw, '\r','')), '') IS NULL THEN NULL
    WHEN TRIM(REPLACE(@review_creation_date_raw, '\r','')) LIKE '%AM'
      OR TRIM(REPLACE(@review_creation_date_raw, '\r','')) LIKE '%PM'
      THEN STR_TO_DATE(TRIM(REPLACE(@review_creation_date_raw, '\r','')), '%c/%e/%Y %l:%i:%s %p')
    ELSE STR_TO_DATE(TRIM(REPLACE(@review_creation_date_raw, '\r','')), '%c/%e/%Y %H:%i')
  END,

review_answer_timestamp =
  CASE
    WHEN NULLIF(TRIM(REPLACE(@review_answer_timestamp_raw, '\r','')), '') IS NULL THEN NULL
    WHEN TRIM(REPLACE(@review_answer_timestamp_raw, '\r','')) LIKE '%AM'
      OR TRIM(REPLACE(@review_answer_timestamp_raw, '\r','')) LIKE '%PM'
      THEN STR_TO_DATE(TRIM(REPLACE(@review_answer_timestamp_raw, '\r','')), '%c/%e/%Y %l:%i:%s %p')
    ELSE STR_TO_DATE(TRIM(REPLACE(@review_answer_timestamp_raw, '\r','')), '%c/%e/%Y %H:%i')
  END;


/* ============================================================
   ADD FOREIGN KEYS AFTER LOADING
   ============================================================ */

ALTER TABLE orders
  ADD CONSTRAINT fk_orders_customer
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE order_items
  ADD CONSTRAINT fk_order_items_order
  FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_payments
  ADD CONSTRAINT fk_order_payments_order
  FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_reviews
  ADD CONSTRAINT fk_order_reviews_order
  FOREIGN KEY (order_id) REFERENCES orders(order_id);

SHOW TABLES;
