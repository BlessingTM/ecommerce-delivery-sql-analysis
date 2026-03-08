# E-commerce Delivery Performance Analysis (SQL)

## Project Overview
This SQL project analyzes delivery performance using the Brazilian Olist e-commerce dataset.

The goal of the analysis is to understand delivery efficiency and identify late deliveries using SQL queries in SQLite.

## Business Questions
This project answers the following questions:

1. How many orders exist in the dataset?
2. Are there missing values in important columns?
3. How long do deliveries typically take?
4. Which orders took longer than the average delivery time?
5. How many orders were never delivered?
6. How many orders were delivered late?
7. What percentage of deliveries were late?
8. Which sellers are responsible for the most late deliveries?

## SQL Concepts Used
- SELECT
- WHERE
- COUNT()
- AVG()
- MAX() / MIN()
- ROUND()
- GROUP BY
- ORDER BY
- LIMIT
- JOIN
- Subqueries
- Common Table Expressions (CTE)
- CREATE VIEW
- Date calculations with JULIANDAY()

## Dataset
Brazilian E-commerce Public Dataset by Olist.

Tables used:
- `olist_orders`
- `olist_order_items`

## Key Insights
- Delivery time can be calculated using the difference between purchase date and delivery date.
- Some orders take significantly longer than the average delivery time.
- A measurable percentage of orders are delivered later than the estimated delivery date.
- Certain sellers contribute more frequently to late deliveries.

## Project Files
