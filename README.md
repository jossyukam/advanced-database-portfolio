# Advanced Database Systems Portfolio (MIT 8103)

**Student:** Joseph Uduma, 301921780
**Case study:** NaijaMart, a simulated Nigerian e-commerce platform with customers, products, orders, payments and deliveries.
**Environment:** PostgreSQL 16 and Redis, both run on my own MacBook. All five portfolios use this one case study.

## Portfolio overview
| Portfolio | Folder | Technology | What I ran | Status |
|---|---|---|---|---|
| 1 Database design and modelling | `portfolio-1-database-design/` | PostgreSQL, Graphviz | Schema (9 tables) and seed script; ER diagram | Run |
| 2 Query processing and optimisation | `portfolio-2-query-optimisation/` | PostgreSQL `EXPLAIN ANALYZE` | 4 queries, before and after 4 indexes | Run |
| 3 Transactions and concurrency | `portfolio-3-transactions-concurrency/` | PostgreSQL, two simultaneous sessions | Commit, rollback, savepoint; overselling test; isolation levels | Run |
| 4 NoSQL and advanced data models | `portfolio-4-nosql/` | Redis, MongoDB | Redis carts, sessions, ranking and stock script | Redis run. **MongoDB is design only and was not executed** |
| 5 Distributed and cloud | `portfolio-5-distributed-cloud/` | PostgreSQL replication and partitioning | Streaming replication, failover, hash partitioning | Run locally. **No cloud deployment** |

## Key results
**Portfolio 1.** The database holds 20,000 customers, 5,000 products and 200,000 orders with about 400,000 order lines. The design is in third normal form, with one deliberate exception: `order_items.unit_price` copies the price at the time of sale so old orders do not change when prices change.

**Portfolio 2.** Query times from `EXPLAIN ANALYZE`, before and after indexing:

| Query | Before | After |
|---|---|---|
| Q1 Order history for one customer | 231.25 ms | 3.81 ms |
| Q2 Top 10 products by revenue, last 90 days | 437.36 ms | 104.55 ms |
| Q3 Pending orders in the last 7 days | 17.87 ms | 1.06 ms |
| Q4 Orders containing one product | 18.11 ms | 0.50 ms |

Q1, Q3 and Q4 are selective, so an index lets PostgreSQL skip most of the table. Q4 needed its own index on `product_id` because the primary key starts with `order_id`. Q2 reads a large share of the data, so an index only helped one part of its plan, and part of its improvement is probably down to the first run being slower, as I explain in that folder's README.

**Portfolio 3.** Using a stock of 1, two buyers at once with a plain read-then-write both succeeded and recorded **2 sales**. With `SELECT ... FOR UPDATE` only **1 sale** was recorded and the second buyer was refused. With READ COMMITTED a reader saw a price change in the middle of its transaction (100000 then 120000); with REPEATABLE READ it saw 100000 both times. The rollback test left stock unchanged after a failed order.

**Portfolio 4.** In Redis, a cart hash, a session key with expiry and a best-sellers sorted set worked as expected. Plain `DECR` let stock fall to -1, while the Lua script refused the second and third buyer and left stock at 0. The MongoDB document model is written but untested.

**Portfolio 5.** A standby server streamed from the primary asynchronously, refused writes, and accepted writes after promotion. After the promotion the old primary still showed stock 10 while the new one showed 7, which is split-brain. Partitioning orders into four hash partitions gave about 50,000 rows each. A query on `customer_id` read one partition and a query on `status` read all four. This is partitioning on a single server, not true sharding.

## Limitations
- MongoDB was not installed or run, so that part is design only.
- Nothing was deployed to a cloud provider. The cloud section of Portfolio 5 is discussion.
- Timings come from single runs on one laptop and will vary.
- Both replication servers ran on the same computer, so this does not show real network behaviour.

## How to reproduce
1. Install PostgreSQL 16 and Redis, and create a database called `shopdb`.
2. In `portfolio-1-database-design/`, run `Uduma_Joseph_301921780_01_schema.sql` and then `Uduma_Joseph_301921780_02_seed_data.sql`. Seeding takes a few minutes.
3. Follow the README inside each portfolio folder. Each one lists its commands and the evidence file it produces. Run commands from inside that portfolio's folder.
4. The Portfolio 5 replication script needs two extra PostgreSQL servers on ports 5433 and 5434, set up as described in that folder's README.

## Repository layout
Each portfolio folder contains its scripts, a README, and an `evidence/` folder with saved outputs and screenshots.

## Tools and references
- PostgreSQL 16 documentation: https://www.postgresql.org/docs/16/
- Redis documentation: https://redis.io/docs/
- MongoDB manual: https://www.mongodb.com/docs/manual/
- Graphviz: https://graphviz.org/

## AI use declaration
I used an AI assistant (Claude, by Anthropic) to help draft the SQL, shell and Redis scripts and the README text for this case study. I then ran all of the PostgreSQL and Redis scripts myself on my MacBook and replaced the sample figures in the READMEs with my own results. I edited the replication script's paths to suit my machine. The MongoDB script was not run.
