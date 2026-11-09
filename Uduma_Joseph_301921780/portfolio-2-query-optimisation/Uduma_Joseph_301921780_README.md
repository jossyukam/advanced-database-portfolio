# Portfolio 2: Query Processing and Optimisation

**Case study:** NaijaMart e-commerce (see Portfolio 1). **DBMS:** PostgreSQL 16.
**Data volume:** 200,000 orders, about 400,000 order lines, 5,000 products.

## Files
| File | Purpose |
|---|---|
| `Uduma_Joseph_301921780_queries.sql` | Four queries, each run with `EXPLAIN (ANALYZE, BUFFERS)` |
| `Uduma_Joseph_301921780_indexes.sql` | Indexes created after the baseline run |
| `evidence/Uduma_Joseph_301921780_plans_before.txt` | Full execution plans with no secondary indexes |
| `evidence/Uduma_Joseph_301921780_plans_after.txt` | Full execution plans after indexing |

## Method
1. Dropped any secondary indexes and ran `Uduma_Joseph_301921780_queries.sql`, saving the plans (baseline).
2. Ran `Uduma_Joseph_301921780_indexes.sql`, then `ANALYZE` to refresh statistics.
3. Re-ran the same `Uduma_Joseph_301921780_queries.sql` and saved the plans.

## Results (execution time from `EXPLAIN ANALYZE`)
| Query | Before | After | Plan change |
|---|---|---|---|
| Q1 Order history for one customer | 11.78 ms | 0.15 ms | Parallel Seq Scan to Bitmap Index Scan on `idx_orders_customer_date` |
| Q2 Top 10 products by revenue (90 days) | 117.52 ms | 97.64 ms | `orders` scan uses `idx_orders_status_date`; `order_items` still seq scanned |
| Q3 Pending orders, last 7 days | 11.11 ms | 0.47 ms | Parallel Seq Scan to Bitmap Index Scan on `idx_orders_status_date` |
| Q4 Orders containing one product | 13.78 ms | 0.38 ms | Seq Scan on `order_items` to Bitmap Index Scan on `idx_order_items_product`, then PK lookups into `orders` |

Timings come from a single run on a small sandbox server, so treat them as indicative. Re-run on your own machine and use your own numbers in the submission.

## Analysis
- **Q1, Q3, Q4** are selective: they return tens or hundreds of rows out of hundreds of thousands. An index lets the planner jump to those rows instead of reading the whole table, which is why they improved by one to two orders of magnitude.
- **Q4** shows why the composite primary key `(order_id, product_id)` does not help here. A B-tree can only be used efficiently from its leading column, so searching by `product_id` alone needed its own index.
- **Q1 index design:** `(customer_id, order_date DESC)` serves both the filter and the sort.
- **Q2 improved only modestly.** It reads about 20% of `orders` (about 41,000 rows) and joins to every matching order line, so most of the work is a hash join and aggregate over a large row set. An index cannot avoid that. Realistic options are a materialised view or pre-aggregated daily sales table, which would trade freshness for speed. I have not implemented that here.
- **Trade-off:** every index adds storage and slows INSERT/UPDATE on that table. I only added indexes that a measured query used.

## Reproduce
```bash
psql -d shopdb -f ../portfolio-1-database-design/Uduma_Joseph_301921780_01_schema.sql
psql -d shopdb -f ../portfolio-1-database-design/Uduma_Joseph_301921780_02_seed_data.sql
psql -d shopdb -f Uduma_Joseph_301921780_queries.sql   > evidence/Uduma_Joseph_301921780_plans_before.txt
psql -d shopdb -f Uduma_Joseph_301921780_indexes.sql
psql -d shopdb -f Uduma_Joseph_301921780_queries.sql   > evidence/Uduma_Joseph_301921780_plans_after.txt
```
Note: `Uduma_Joseph_301921780_02_seed_data.sql` took close to 3 minutes in my sandbox; reduce the `generate_series` counts if yours is slow.
