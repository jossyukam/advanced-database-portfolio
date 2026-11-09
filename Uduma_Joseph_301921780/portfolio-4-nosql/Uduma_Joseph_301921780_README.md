# Portfolio 4: NoSQL and Advanced Data Models

**Case study:** NaijaMart e-commerce. Same organisation as Portfolios 1 to 3.

## What was actually run
| Part | Model | Status |
|---|---|---|
| `Uduma_Joseph_301921780_redis_cart_and_ranking.redis`, `Uduma_Joseph_301921780_guarded_decrement.lua`, `Uduma_Joseph_301921780_run_redis.sh` | Key-value (Redis) | **Executed on my MacBook.** Output is in `evidence/Uduma_Joseph_301921780_redis_output.txt` |
| `Uduma_Joseph_301921780_mongodb_product_catalogue.js` | Document (MongoDB) | **Design only. I did not run it**, because I did not have MongoDB installed. The script and queries are included to show the model, but they have not been tested. |

## Key-value store (Redis): where it fits NaijaMart
| Need | Redis structure | Why it fits |
|---|---|---|
| Shopping cart | Hash `cart:<customer_id>`, one field per product, value = quantity | Very fast reads and writes. Carts are temporary, so `EXPIRE` can clear abandoned ones automatically |
| Login session | String with a 30 minute expiry (`EX 1800`) | Simple lookup by token that cleans itself up |
| Best-sellers ranking | Sorted set `bestsellers`, score = units sold | `ZINCRBY` updates a score and `ZREVRANGE` returns the top N already sorted, without a heavy SQL aggregate |
| Stock counter for flash sales | Integer key plus a Lua script | Atomic and very low latency |

### What I saw when I ran it
- **Cart:** I added 2 of `prod:777` and 1 of `prod:42` to `cart:1234`. `HINCRBY` raised the quantity of `prod:777` from 2 to **3**. I set a 7 day expiry and `TTL` returned **604800** seconds.
- **Session:** `session:abc123` stored `customer:1234` and returned it with `GET`. It was set to expire after 1800 seconds.
- **Ranking:** After several `ZINCRBY` calls, the top of the leaderboard was `prod:777` with **8** sales, then `prod:900` with **7**, then `prod:42` with **1**. `ZREVRANK` placed `prod:42` third (rank 2, counting from 0).
- **Stock with plain `DECR`:** I set stock to 1 and decremented twice. The result was **0**, then **-1**. Each `DECR` is atomic, so nothing is lost or overwritten, but Redis has no rule against stock going negative, so it oversold an item that wasn't there.
- **Stock with the Lua script:** With stock at 1 and three buyers, buyer 1 got **0** (a successful purchase), and buyers 2 and 3 got **-1**. In my script `-1` is the "refused, out of stock" signal, not a stock level. The final stock stayed at **0**.

### Why plain `DECR` is not enough, and what the Lua script adds
`DECR` does only one thing: subtract 1. It does not check anything first. If I check the stock with one command and decrement with another, two buyers can still slip in between those commands, which is the same overselling problem I showed in Portfolio 3. The Lua script reads the stock, checks it is above 0, and decrements it as one unit. Redis runs a Lua script without interleaving other commands, so the check and the change cannot be split by another buyer.

### Limits
Redis keeps its data in memory, and in this run I turned persistence off (`--save ""`), so the data disappears on restart. That is fine for carts, sessions and rankings, which can be rebuilt or are short-lived. It is not acceptable for orders and payments.

## Document model (MongoDB): why and how (design only)
- **Products** vary a lot by category. A phone has RAM and storage, shoes have sizes and material. In a relational table that means many columns that are empty for most rows, or an awkward extra table. A document can hold exactly the attributes a given product has.
- **Orders** embed their line items, since they are read and written together. The product name and unit price are copied into the order, so old orders stay correct when the catalogue changes, as in my relational design.
- **Trade-offs:** embedding repeats data, and an update to a product name does not reach past orders. Here that is what I want. Multi-document consistency is also weaker or more costly than in PostgreSQL, so payments and stock should stay in the relational database.

## Which store for what (polyglot persistence)
- **PostgreSQL:** orders, payments, stock and anything where correctness matters most, because it has transactions and constraints.
- **Redis:** carts, sessions and rankings, where speed matters and the data can be rebuilt.
- **Document store:** the product catalogue, where attributes differ from product to product.

## Reproduce
```bash
redis-server --port 6380 --daemonize yes --save ""
bash Uduma_Joseph_301921780_run_redis.sh
# MongoDB part is untested design only:
# mongosh naijamart < Uduma_Joseph_301921780_mongodb_product_catalogue.js
```
Note that the script starts with `FLUSHDB`, which deletes everything in the Redis database it connects to, so only run it against a throwaway instance like this one.
