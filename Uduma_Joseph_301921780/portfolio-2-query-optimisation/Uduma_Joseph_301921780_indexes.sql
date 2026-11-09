SET search_path = shop;
-- Q1: equality lookup on the foreign key; also supports joins from customers
CREATE INDEX idx_orders_customer_date ON orders (customer_id, order_date DESC);
-- Q2/Q3: filter on status plus date range
CREATE INDEX idx_orders_status_date ON orders (status, order_date);
-- Q4: PK is (order_id, product_id), so searching by product_id alone cannot use it
CREATE INDEX idx_order_items_product ON order_items (product_id);
-- Join support for payment lookups per order
CREATE INDEX idx_payments_order ON payments (order_id);
ANALYZE;
