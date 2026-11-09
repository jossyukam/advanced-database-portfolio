SET search_path = shop;
\echo '=== Q1: order history for one customer ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.order_id, o.order_date, o.status
FROM orders o
WHERE o.customer_id = 1234
ORDER BY o.order_date DESC;

\echo '=== Q2: top 10 products by revenue, last 90 days (join + aggregate) ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.product_id, p.name, SUM(i.quantity * i.unit_price) AS revenue
FROM orders o
JOIN order_items i ON i.order_id = o.order_id
JOIN products p    ON p.product_id = i.product_id
WHERE o.order_date >= now() - interval '90 days'
  AND o.status IN ('PAID','SHIPPED','DELIVERED')
GROUP BY p.product_id, p.name
ORDER BY revenue DESC
LIMIT 10;

\echo '=== Q3: pending orders in the last 7 days (selective filter) ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, customer_id, order_date
FROM orders
WHERE status = 'PENDING'
  AND order_date >= now() - interval '7 days';

\echo '=== Q4: all orders containing one product ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.order_id, o.order_date, i.quantity
FROM order_items i
JOIN orders o ON o.order_id = i.order_id
WHERE i.product_id = 777;
