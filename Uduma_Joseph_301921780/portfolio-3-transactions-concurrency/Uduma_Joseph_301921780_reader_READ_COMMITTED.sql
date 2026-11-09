SET search_path = shop;
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT price AS "reader first read" FROM products WHERE product_id = 9003;
SELECT pg_sleep(2) \gset
SELECT price AS "reader second read (READ COMMITTED)" FROM products WHERE product_id = 9003;
COMMIT;
