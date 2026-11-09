-- Hash partitioning orders by customer_id into 4 partitions. This is SINGLE-NODE partitioning;
-- true sharding would place each partition on a different server.
SET search_path = shop;
DROP TABLE IF EXISTS orders_sharded CASCADE;
CREATE TABLE orders_sharded (
  order_id BIGINT NOT NULL, customer_id INT NOT NULL, status VARCHAR(20), order_date TIMESTAMP,
  PRIMARY KEY (customer_id, order_id)
) PARTITION BY HASH (customer_id);
CREATE TABLE orders_shard_0 PARTITION OF orders_sharded FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE orders_shard_1 PARTITION OF orders_sharded FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE orders_shard_2 PARTITION OF orders_sharded FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE orders_shard_3 PARTITION OF orders_sharded FOR VALUES WITH (MODULUS 4, REMAINDER 3);
INSERT INTO orders_sharded SELECT order_id, customer_id, status, order_date FROM orders;
ANALYZE orders_sharded;
\echo '--- rows per shard ---'
SELECT tableoid::regclass AS shard, count(*) FROM orders_sharded GROUP BY 1 ORDER BY 1;
\echo '--- query with the shard key: only ONE shard is read (partition pruning) ---'
EXPLAIN SELECT * FROM orders_sharded WHERE customer_id = 1234;
\echo '--- query without the shard key: ALL shards are read (scatter-gather) ---'
EXPLAIN SELECT count(*) FROM orders_sharded WHERE status = 'PENDING';
