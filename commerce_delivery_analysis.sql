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
-- =========================================================

SELECT *
FROM olist_orders oo
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
       JULIANDAY(order_delivered_customer_date) - JULIANDAY(order_purchase_timestamp) AS delivery_days
FROM olist_orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date != ''
ORDER BY delivery_days;


-- =========================================================
-- 5. Orders Delivered Slower Than Average
-- Business Question:
-- Which orders took longer than the average delivery time?
-- =========================================================

WITH delivered_orders AS (
    SELECT order_id,
           order_purchase_timestamp,
           order_delivered_customer_date,
           JULIANDAY(order_delivered_customer_date) - JULIANDAY(order_purchase_timestamp) AS delivery_days
    FROM olist_orders
    WHERE order_delivered_customer_date IS NOT NULL
)
SELECT order_id,
       order_purchase_timestamp,
       order_delivered_customer_date,
       delivery_days
FROM delivered_orders
WHERE delivery_days > (
    SELECT AVG(delivery_days)
    FROM delivered_orders
);


-- =========================================================
-- 6. Count of Orders Delivered Slower Than Average
-- Business Question:
-- How many orders took longer than the average delivery time?
-- =========================================================

WITH delivered_orders AS (
    SELECT order_id,
           order_purchase_timestamp,
           order_delivered_customer_date,
           JULIANDAY(order_delivered_customer_date) - JULIANDAY(order_purchase_timestamp) AS delivery_days
    FROM olist_orders
    WHERE order_delivered_customer_date IS NOT NULL
)
SELECT COUNT(*) AS orders_above_avg_delivery
FROM delivered_orders
WHERE delivery_days > (
    SELECT AVG(delivery_days)
    FROM delivered_orders
);


-- =========================================================
-- 7. Orders Not Delivered
-- Business Question:
-- How many orders were not delivered?
-- =========================================================

WITH not_delivered AS (
    SELECT *
    FROM olist_orders
    WHERE order_delivered_customer_date IS NULL
       OR order_delivered_customer_date = ''
)
SELECT COUNT(*) AS not_delivered_orders
FROM not_delivered;


-- =========================================================
-- 8. Late Delivery View
-- Business Question:
-- Which orders were delivered at least 1 day later than the
-- estimated delivery date?
-- =========================================================
DROP VIEW IF EXISTS LATE_DELIVERY;

CREATE VIEW LATE_DELIVERY AS
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
-- 9. Distribution of Late Delivery Days
-- Business Question:
-- How many orders were late by 1 day, 2 days, 3 days, etc.?
-- =========================================================

SELECT late_delivery_day,
       COUNT(*) AS number_of_orders
FROM LATE_DELIVERY
GROUP BY late_delivery_day
ORDER BY late_delivery_day;


-- =========================================================
-- 10. Average Late Delivery Days
-- Business Question:
-- For late orders only, what was the average number of late days?
-- =========================================================

SELECT ROUND(AVG(late_delivery_day), 2) AS avg_late_delivery_days
FROM LATE_DELIVERY;


-- =========================================================
-- 11. Late Delivery Severity
-- Business Question:
-- What are the minimum, maximum, and average late delivery days?
-- =========================================================

SELECT MAX(late_delivery_day) AS max_late_days,
       MIN(late_delivery_day) AS min_late_days,
       ROUND(AVG(late_delivery_day), 2) AS avg_late_days
FROM LATE_DELIVERY;


-- =========================================================
-- 12. Number of Late Deliveries
-- Business Question:
-- How many orders were delivered late?
-- =========================================================

SELECT COUNT(*) AS late_delivery_count
FROM LATE_DELIVERY;


-- =========================================================
-- 13. Late Delivery Percentage
-- Business Question:
-- What percentage of delivered orders were delivered late?
-- =========================================================

SELECT ROUND(
    (SELECT COUNT(*) FROM LATE_DELIVERY) * 100.0 /
    (SELECT COUNT(*)
     FROM olist_orders
     WHERE order_delivered_customer_date IS NOT NULL
       AND order_delivered_customer_date != ''),
    2
) AS late_delivery_percentage;

-- =========================================================
-- 14. Seller Late Delivery Responsibility
-- Business Question:
-- Which sellers are responsible for the most late deliveries?
-- =========================================================

SELECT oi.seller_id,
       COUNT(*) AS late_orders,
       ROUND(AVG(ld.late_delivery_day), 2) AS avg_late_days
FROM LATE_DELIVERY ld
JOIN olist_order_items oi
    ON ld.order_id = oi.order_id
GROUP BY oi.seller_id
ORDER BY late_orders DESC
LIMIT 10;
