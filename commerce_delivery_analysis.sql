-- =========================================================
-- E-commerce Delivery Performance Analysis
-- Entry-Level SQL Project
-- =========================================================

-- =========================================================
-- 1. Initial Table Check
-- Business Question:
-- How many records are in the orders table?
-- =========================================================

SELECT COUNT(*) AS total_orders
FROM olist_orders;


-- =========================================================
-- 2. Table Structure Review
-- Business Question:
-- What columns are available in the orders table?
-- =========================================================

PRAGMA TABLE_INFO(olist_orders);


-- =========================================================
-- 3. Missing Values Check
-- Business Question:
-- Are there missing values in important order fields?
-- Note:
-- Some NULLs may reflect undelivered or canceled orders rather
-- than true data quality issues.
-- =========================================================

SELECT *
FROM olist_orders
WHERE order_id IS NULL
   OR customer_id IS NULL
   OR order_status IS NULL
   OR order_purchase_timestamp IS NULL
   OR order_approved_at IS NULL
   OR order_delivered_carrier_date IS NULL
   OR order_delivered_customer_date IS NULL
   OR order_estimated_delivery_date IS NULL;


-- =========================================================
-- 4. Delivery Days Per Order
-- Business Question:
-- How many days did each delivered order take?
-- =========================================================

SELECT order_id,
       order_purchase_timestamp,
       order_delivered_customer_date,
       CAST(
           JULIANDAY(order_delivered_customer_date) -
           JULIANDAY(order_purchase_timestamp)
           AS INTEGER
       ) AS delivery_days
FROM olist_orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date != ''
ORDER BY delivery_days;


-- =========================================================
-- 5. Delivered Orders View
-- Business Question:
-- Can we create a reusable view for delivered orders and their
-- delivery time in days?
-- =========================================================

DROP VIEW IF EXISTS delivered_orders;

CREATE VIEW delivered_orders AS
SELECT order_id,
       order_purchase_timestamp,
       order_delivered_customer_date,
       CAST(
           JULIANDAY(order_delivered_customer_date) -
           JULIANDAY(order_purchase_timestamp)
           AS INTEGER
       ) AS delivery_days
FROM olist_orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date != '';


-- =========================================================
-- 6. Orders Delivered Slower Than Average
-- Business Question:
-- Which orders took longer than the average delivery time?
-- =========================================================

SELECT order_id,
       order_purchase_timestamp,
       order_delivered_customer_date,
       delivery_days
FROM delivered_orders
WHERE delivery_days > (
    SELECT AVG(delivery_days)
    FROM delivered_orders
)
ORDER BY delivery_days DESC;


-- =========================================================
-- 7. Count of Orders Delivered Slower Than Average
-- Business Question:
-- How many orders took longer than the average delivery time?
-- =========================================================

SELECT COUNT(*) AS orders_above_avg_delivery
FROM delivered_orders
WHERE delivery_days > (
    SELECT AVG(delivery_days)
    FROM delivered_orders
);


-- =========================================================
-- 8. Orders Not Delivered View
-- Business Question:
-- Can we create a reusable view for orders that were not
-- delivered?
-- =========================================================

DROP VIEW IF EXISTS not_delivered;

CREATE VIEW not_delivered AS
SELECT *
FROM olist_orders
WHERE order_delivered_customer_date IS NULL
   OR order_delivered_customer_date = '';


-- =========================================================
-- 9. Orders Not Delivered Count
-- Business Question:
-- How many orders were not delivered?
-- =========================================================

SELECT COUNT(*) AS not_delivered_orders
FROM not_delivered;


-- =========================================================
-- 10. Late Delivery View
-- Business Question:
-- Which orders were delivered at least 1 day later than the
-- estimated delivery date?
-- =========================================================

DROP VIEW IF EXISTS late_delivery;

CREATE VIEW late_delivery AS
SELECT order_id,
       order_delivered_customer_date,
       order_estimated_delivery_date,
       CAST(
           JULIANDAY(order_delivered_customer_date) -
           JULIANDAY(order_estimated_delivery_date)
           AS INTEGER
       ) AS late_delivery_day
FROM olist_orders
WHERE JULIANDAY(order_delivered_customer_date) -
      JULIANDAY(order_estimated_delivery_date) >= 1;


-- =========================================================
-- 11. Distribution of Late Delivery Days
-- Business Question:
-- How many orders were late by 1 day, 2 days, 3 days, etc.?
-- =========================================================

SELECT late_delivery_day,
       COUNT(*) AS number_of_orders
FROM late_delivery
GROUP BY late_delivery_day
ORDER BY late_delivery_day;


-- =========================================================
-- 12. Average Late Delivery Days
-- Business Question:
-- For late orders only, what was the average number of late days?
-- =========================================================

SELECT ROUND(AVG(late_delivery_day), 2) AS avg_late_delivery_days
FROM late_delivery;


-- =========================================================
-- 13. Late Delivery Severity
-- Business Question:
-- What are the minimum, maximum, and average late delivery days?
-- =========================================================

SELECT MAX(late_delivery_day) AS max_late_days,
       MIN(late_delivery_day) AS min_late_days,
       ROUND(AVG(late_delivery_day), 2) AS avg_late_days
FROM late_delivery;


-- =========================================================
-- 14. Number of Late Deliveries
-- Business Question:
-- How many orders were delivered late?
-- =========================================================

SELECT COUNT(*) AS late_delivery_count
FROM late_delivery;


-- =========================================================
-- 15. Late Delivery Percentage
-- Business Question:
-- What percentage of delivered orders were delivered late?
-- =========================================================

SELECT ROUND(
    (SELECT COUNT(*) FROM late_delivery) * 100.0 /
    (SELECT COUNT(*)
     FROM olist_orders
     WHERE order_delivered_customer_date IS NOT NULL
       AND order_delivered_customer_date != ''),
    2
) AS late_delivery_percentage;


-- =========================================================
-- 16. Seller Late Delivery Responsibility
-- Business Question:
-- Which sellers are associated with the most late deliveries?
-- Note:
-- COUNT(DISTINCT ld.order_id) is used to avoid overcounting
-- when an order contains multiple items.
-- =========================================================

SELECT oi.seller_id,
       COUNT(DISTINCT ld.order_id) AS late_orders,
       ROUND(AVG(ld.late_delivery_day), 2) AS avg_late_days
FROM late_delivery ld
JOIN olist_order_items oi
    ON ld.order_id = oi.order_id
GROUP BY oi.seller_id
ORDER BY late_orders DESC
LIMIT 10;
