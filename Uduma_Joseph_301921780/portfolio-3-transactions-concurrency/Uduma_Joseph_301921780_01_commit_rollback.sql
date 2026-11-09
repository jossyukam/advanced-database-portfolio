SET search_path = shop;
\echo '--- setup: product 9001 with stock 5 ---'
INSERT INTO products(product_id, category_id, name, price, stock_qty) VALUES (9001, 1, 'Txn Demo Phone', 100000, 5)
ON CONFLICT (product_id) DO UPDATE SET stock_qty = 5;

\echo '--- 1. COMMIT: place an order for 2 units ---'
BEGIN;
INSERT INTO orders(customer_id, address_id, status) VALUES (1, 1, 'PAID') RETURNING order_id \gset
INSERT INTO order_items VALUES (:order_id, 9001, 2, 100000);
UPDATE products SET stock_qty = stock_qty - 2 WHERE product_id = 9001;
INSERT INTO stock_log(product_id, change_qty, reason) VALUES (9001, -2, 'order ' || :order_id);
COMMIT;
SELECT product_id, stock_qty FROM products WHERE product_id = 9001;

\echo '--- 2. ROLLBACK on failure: try to buy 10 units but only 3 remain ---'
BEGIN;
INSERT INTO orders(customer_id, address_id, status) VALUES (1, 1, 'PAID') RETURNING order_id \gset
INSERT INTO order_items VALUES (:order_id, 9001, 10, 100000);
UPDATE products SET stock_qty = stock_qty - 10 WHERE product_id = 9001;  -- violates CHECK (stock_qty >= 0)
ROLLBACK;
\echo 'stock is unchanged and the failed order does not exist:'
SELECT product_id, stock_qty FROM products WHERE product_id = 9001;
SELECT count(*) AS order_rows_with_10_units FROM order_items WHERE product_id = 9001 AND quantity = 10;

\echo '--- 3. SAVEPOINT: partial rollback inside one transaction ---'
BEGIN;
UPDATE products SET stock_qty = stock_qty - 1 WHERE product_id = 9001;
SAVEPOINT sp1;
UPDATE products SET stock_qty = stock_qty - 100 WHERE product_id = 9001;  -- fails
ROLLBACK TO sp1;
COMMIT;
SELECT product_id, stock_qty FROM products WHERE product_id = 9001;
