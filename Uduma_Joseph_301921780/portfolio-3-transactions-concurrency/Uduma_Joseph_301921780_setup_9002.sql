SET search_path = shop;
INSERT INTO products(product_id, category_id, name, price, stock_qty) VALUES (9002, 1, 'Last Unit Demo', 50000, 1)
ON CONFLICT (product_id) DO UPDATE SET stock_qty = 1;
DELETE FROM stock_log WHERE product_id = 9002;
