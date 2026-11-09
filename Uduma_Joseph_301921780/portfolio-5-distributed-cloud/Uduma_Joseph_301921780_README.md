# Portfolio 5: Distributed and Cloud Database Exercise

**Case study:** NaijaMart e-commerce. **DBMS:** PostgreSQL 16 on my MacBook. For the replication part, the primary and the standby are two separate PostgreSQL servers running on the same computer, on different ports (5433 and 5434).

## What was actually run
| Part | Files | Evidence |
|---|---|---|
| Streaming replication, read-only standby and failover | `Uduma_Joseph_301921780_replication_demo.sh` | `evidence/Uduma_Joseph_301921780_replication_output.txt` |
| Hash partitioning, as a single-server stand-in for sharding | `Uduma_Joseph_301921780_partition_demo.sql` | `evidence/Uduma_Joseph_301921780_partition_output.txt` |
| Cloud deployment | Discussion only (section 4). **I did not deploy anything to a cloud provider.** | None |

## How I set up replication
The primary is a separate server from my main database, so nothing from Portfolios 1 to 4 was touched. I loaded only the schema from Portfolio 1 and one category row into it, which is enough for this demo.
```bash
initdb -D ~/pgprimary
pg_ctl -D ~/pgprimary -o "-p 5433" -l ~/pgprimary.log -w start
createdb -p 5433 shopdb
psql -p 5433 -d shopdb -f ../portfolio-1-database-design/Uduma_Joseph_301921780_01_schema.sql
psql -p 5433 -d shopdb -c "insert into shop.categories(name) values ('Phones')"

pg_basebackup -h localhost -p 5433 -D ~/pgstandby -R -X stream --checkpoint=fast
pg_ctl -D ~/pgstandby -o "-p 5434" -l ~/pgstandby.log -w start
```
`pg_basebackup` copies the primary's data, and the `-R` flag writes the settings that make the copy follow the primary as a standby. I used `--checkpoint=fast` so the copy starts straight away.

## 1. Replication and availability
- On the primary, `pg_stat_replication` showed the standby as **streaming** and **async** (asynchronous). In the demo run the replay lag was about 0.0006 seconds. In my first check the lag column was empty, which just means there had been no recent activity to measure.
- I inserted a product (9500) on the primary. It appeared on the standby straight away, with stock 10.
- I then tried to update that product on the standby. It was refused with `cannot execute UPDATE in a read-only transaction`. This shows the standby is a read-only copy. It can serve reads, such as product browsing and reports, which takes load off the primary.
- **Failover:** I promoted the standby. After that, `pg_is_in_recovery()` returned false, meaning it was a normal writable server, and my update of the stock to 7 succeeded. This is what would let the shop keep working if the primary failed.

## 2. Consistency and availability trade-off
Replication here is **asynchronous**. The primary confirms a write without waiting for the standby, which is fast. The risk is that if the primary failed right after confirming a write, that write might not have reached the standby yet and would be lost after failover. Synchronous replication (`synchronous_standby_names`) closes that gap, but each commit then waits for the standby, and writes can stall if the standby is unreachable. This is the usual choice between consistency and availability (the CAP theorem, and its extension PACELC, which also includes latency). For NaijaMart, orders and payments justify the safer synchronous option. Product browsing can accept slightly out-of-date reads.

**Split-brain, which I saw happen:** after promoting the standby I changed the stock to 7 on the new primary. The old primary still showed stock 10. Both servers were now independent and writable, and their data had diverged. In a real system the old primary has to be shut down or demoted (fenced) before failover, and clients must be sent to only one writable server, otherwise two copies of the truth will exist. Tools such as Patroni automate this.

## 3. Sharding
`Uduma_Joseph_301921780_partition_demo.sql` splits the orders table into four hash partitions using `customer_id` as the key.
- The rows were spread almost evenly: 49,998, 50,554, 50,072 and 49,377 across the four partitions, so the hash split the data fairly.
- A query with the shard key (`customer_id = 1234`) read **only one** partition (`orders_shard_2`). This is called partition pruning.
- A query without the shard key (`status = 'PENDING'`) had to scan **all four** partitions and combine the results. This is called scatter-gather.

**What this does not show:** all four partitions are on one server, so this is partitioning, not true sharding, and it adds no extra capacity. Real sharding would place each partition on a different server, for example with Citus or routing logic in the application. Choosing `customer_id` keeps one customer's orders together, which is good for order history. The cost is that reports across all customers, or queries filtered by something else such as status, have to hit every shard.

## 4. Cloud deployment (discussion only, not deployed)
I did not deploy a database to the cloud for this portfolio. For NaijaMart on a managed PostgreSQL service (for example AWS RDS or Aurora, Google Cloud SQL, or Azure Database for PostgreSQL), a sensible design would be:
- A primary in one availability zone with a synchronous standby in another, with automatic failover.
- One or more read replicas for reporting and catalogue browsing.
- Automated backups with point-in-time recovery, and encryption at rest and in transit.
- A managed Redis service for carts and sessions, as in Portfolio 4.
- A region close to the customers to reduce latency. Services and costs would need to be checked against each provider's current documentation before choosing.

## Reproduce
Partitioning (uses the main `shopdb` from Portfolio 1):
```bash
psql -d shopdb -q -f Uduma_Joseph_301921780_partition_demo.sql
```
Replication: set up the two servers as shown above, then run the demo script. It contains paths for my machine's setup, which I edited with `sed` to match my MacBook before running it.
```bash
bash Uduma_Joseph_301921780_replication_demo.sh
```
When finished, stop both servers: `pg_ctl -D ~/pgstandby stop` and `pg_ctl -D ~/pgprimary stop`.
