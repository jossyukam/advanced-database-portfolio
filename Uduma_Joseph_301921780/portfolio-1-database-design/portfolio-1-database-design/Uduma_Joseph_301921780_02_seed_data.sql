-- Seed data: realistic volume so that Portfolio 2 execution plans are meaningful.
SET search_path = shop;
SELECT setseed(0.42);

INSERT INTO categories(name) VALUES
 ('Phones'),('Laptops'),('Fashion'),('Groceries'),('Home & Kitchen'),('Beauty'),('Books'),('Sports');

INSERT INTO customers(full_name, email, phone, created_at)
SELECT 'Customer ' || g,
       'customer' || g || '@example.com',
       '080' || lpad((random()*99999999)::int::text, 8, '0'),
       now() - (random()*700 || ' days')::interval
FROM generate_series(1, 20000) g;

INSERT INTO addresses(customer_id, street, city, state, is_default)
SELECT c.customer_id,
       (1 + (random()*200)::int) || ' Sample Street',
       (ARRAY['Jos','Lagos','Abuja','Kano','Port Harcourt','Ibadan','Enugu'])[1 + (random()*6)::int],
       (ARRAY['Plateau','Lagos','FCT','Kano','Rivers','Oyo','Enugu'])[1 + (random()*6)::int],
       TRUE
FROM customers c;

INSERT INTO products(category_id, name, price, stock_qty)
SELECT 1 + (g % 8),
       'Product ' || g,
       round((500 + random()*499500)::numeric, 2),
       (random()*500)::int
FROM generate_series(1, 5000) g;

INSERT INTO orders(customer_id, address_id, status, order_date)
SELECT c, c,   -- address_id = customer_id because each customer has exactly one seeded address
       (ARRAY['PENDING','PAID','SHIPPED','DELIVERED','DELIVERED','DELIVERED','CANCELLED'])[1 + (random()*6)::int],
       now() - (random()*365 || ' days')::interval
FROM (SELECT 1 + (random()*19999)::int AS c FROM generate_series(1, 200000)) s;

-- 1 to 3 distinct products per order
INSERT INTO order_items(order_id, product_id, quantity, unit_price)
SELECT o.order_id, p.product_id, 1 + (random()*3)::int, p.price
FROM orders o
CROSS JOIN LATERAL (
    SELECT product_id, price FROM products
    WHERE o.order_id > 0
    ORDER BY random() LIMIT (1 + (o.order_id % 3))
) p;

INSERT INTO payments(order_id, amount, method, status, paid_at)
SELECT o.order_id,
       (SELECT sum(quantity*unit_price) FROM order_items i WHERE i.order_id = o.order_id),
       (ARRAY['CARD','TRANSFER','USSD','WALLET'])[1 + (random()*3)::int],
       CASE WHEN o.status = 'PENDING' THEN 'INITIATED'
            WHEN o.status = 'CANCELLED' THEN 'FAILED' ELSE 'SUCCESS' END,
       CASE WHEN o.status IN ('PAID','SHIPPED','DELIVERED') THEN o.order_date + interval '5 minutes' END
FROM orders o;

INSERT INTO deliveries(order_id, courier, status)
SELECT order_id,
       (ARRAY['GIG Logistics','Kwik','DHL','Topship'])[1 + (random()*3)::int],
       CASE status WHEN 'DELIVERED' THEN 'DELIVERED' WHEN 'SHIPPED' THEN 'IN_TRANSIT' ELSE 'PROCESSING' END
FROM orders WHERE status IN ('SHIPPED','DELIVERED');

ANALYZE;
