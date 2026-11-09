# Portfolio 3: Transactions and Concurrency

**Case study:** NaijaMart e-commerce. **DBMS:** PostgreSQL 16 on my MacBook (default isolation level: READ COMMITTED).

## Files
| File | What it does | Evidence |
|---|---|---|
| `Uduma_Joseph_301921780_01_commit_rollback.sql` | Commit, rollback and savepoint examples | `evidence/Uduma_Joseph_301921780_commit_rollback_output.txt` |
| `Uduma_Joseph_301921780_run_concurrency.sh` with the `session_*` and `setup_9002` files | Two buyers going for the last unit, once without locking and once with it | `evidence/Uduma_Joseph_301921780_concurrency_output.txt` |
| `Uduma_Joseph_301921780_run_isolation.sh` with the `reader_*`, `writer` and `setup_9003` files | READ COMMITTED compared with REPEATABLE READ | `evidence/Uduma_Joseph_301921780_isolation_output.txt` |

## 1. Commit and rollback (atomicity)
Placing an order changes four tables: `orders`, `order_items`, the product's stock in `products`, and `stock_log`. Those changes only make sense together, so I wrapped them in one transaction. I used a test product (9001) that starts with 5 units.

- **Commit:** I ordered 2 units and committed. Stock went from 5 to **3**.
- **Rollback:** I then tried to order 10 units. The stock update would have taken stock to -7, so the database rejected it with an error from the `products_stock_qty_check` constraint (the `CHECK (stock_qty >= 0)` I defined in Portfolio 1). I rolled back, and afterwards stock was still **3** and there were **0** order lines for 10 units. The order row and order line I had already inserted inside that transaction disappeared with the rollback, so nothing half-finished was left behind. The `ERROR` messages in the output are expected; they are the demonstration.
- **Savepoint:** Inside one transaction I reduced stock by 1, set a savepoint, then tried to reduce it by 100, which failed the same check. Rolling back to the savepoint undid only the failed step and kept the first one. After committing, stock was **2**.

## 2. The concurrency problem: selling the last unit twice
This is a lost update, a type of race condition. Product 9002 has **1** unit left. Two buyers, A and B, try to buy it at almost the same time. Each session reads the stock, pauses for two seconds (to stand in for the application doing other work), then writes the new stock value and records a sale.

| Version | A sees | B sees | Sales recorded | Final stock |
|---|---|---|---|---|
| Unsafe (plain `SELECT`) | 1 | 1 | **2** | 0 |
| Safe (`SELECT ... FOR UPDATE`) | 1 | 0 | **1** | 0 |

**Why the unsafe version sells it twice:** both sessions read the stock *before* either one had changed it, so both saw 1 and both decided the sale was allowed. Each then wrote its result and recorded a sale. The check ("is there stock?") and the update ("reduce the stock") were two separate steps, and the other buyer slipped in between them. The final stock reads 0, which looks fine, but two sales were recorded for one item, so the data is inconsistent.

**What `FOR UPDATE` does about it:** it puts a lock on that product's row when it is read. Buyer A got the lock first. Buyer B's read had to wait until A committed, and when it finally ran it saw the up-to-date stock of 0, so B was told the item was out of stock and the sale was refused. The check and the update now behave as one step for that product. Other ways to solve the same problem are a single atomic statement such as `UPDATE products SET stock_qty = stock_qty - 1 WHERE stock_qty >= 1`, a version column (optimistic locking), or SERIALIZABLE isolation with a retry when a conflict is detected.

**Trade-off:** locking is correct but makes buyers of the same product queue up. For a very popular item, the single atomic `UPDATE` holds the lock for less time and is probably the better choice.

I used `pg_sleep` in the scripts to force the two sessions to overlap. Without it, the timing would be a matter of luck, and the demonstration would not be repeatable.

## 3. Isolation levels
A reader session reads one product's price twice inside a single transaction. While it waits between the two reads, a writer session changes the price from 100000 to 120000 and commits.

| Isolation level | First read | Second read | What happened |
|---|---|---|---|
| READ COMMITTED | 100000.00 | **120000.00** | The reader saw the committed change halfway through its own transaction (a non-repeatable read) |
| REPEATABLE READ | 100000.00 | **100000.00** | The reader kept working from the same snapshot and the price stayed the same |

READ COMMITTED is PostgreSQL's default and gives each statement the latest committed data. REPEATABLE READ gives a stable view for the whole transaction, which suits reports that must be consistent, but the application has to be ready to retry if PostgreSQL reports a conflict.

## Reproduce
From this folder, with Portfolio 1 loaded in a database called `shopdb`:
```bash
psql -d shopdb -q -f Uduma_Joseph_301921780_01_commit_rollback.sql
bash Uduma_Joseph_301921780_run_concurrency.sh
bash Uduma_Joseph_301921780_run_isolation.sh
```
These demos add a few test rows (products 9001 to 9003 and one extra order) to the database.
