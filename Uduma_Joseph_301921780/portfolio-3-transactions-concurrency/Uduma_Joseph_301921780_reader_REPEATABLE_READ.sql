SET search_path = shop;
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT price AS "reader first read" FROM products WHERE product_id = 9003;
SELECT pg_sleep(2) \gset
SELECT price AS "reader second read (REPEATABLE READ)" FROM products WHERE product_id = 9003;
COMMIT;
