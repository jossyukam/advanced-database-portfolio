SET search_path = shop;
BEGIN;
SELECT (stock_qty >= 1) AS ok, stock_qty AS seen FROM products WHERE product_id = 9002  \gset
\echo '[A] sees stock =' :seen
SELECT pg_sleep(2);
\if :ok
  UPDATE products SET stock_qty = :seen - 1 WHERE product_id = 9002;
  INSERT INTO stock_log(product_id, change_qty, reason) VALUES (9002, -1, 'sale by A');
  \echo '[A] sale recorded'
\else
  \echo '[A] out of stock, sale refused'
\endif
COMMIT;
