SET search_path = shop;
INSERT INTO products(product_id, category_id, name, price, stock_qty) VALUES (9003, 1, 'Isolation Demo', 100000, 10)
ON CONFLICT (product_id) DO UPDATE SET price = 100000;
