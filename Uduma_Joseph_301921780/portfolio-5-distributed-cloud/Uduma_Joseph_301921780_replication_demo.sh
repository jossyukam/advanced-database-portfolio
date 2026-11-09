#!/bin/bash
# Assumes primary on :5433 and streaming standby on :5434 (see README for setup commands).
P="psql -h localhost -p 5433 -d shopdb -q -t"; S="psql -h localhost -p 5434 -d shopdb -q -t"
echo "## 1. Replication status (on primary)"; $P -c "select state, sync_state, replay_lag from pg_stat_replication"
echo "## 2. Write on primary: new product 9500"
$P -c "insert into shop.products(product_id,category_id,name,price,stock_qty) values (9500,1,'Replication Demo',75000,10) on conflict (product_id) do update set stock_qty=10"
sleep 1
echo "## 3. Read on standby (should see product 9500)"; $S -c "select product_id,name,stock_qty from shop.products where product_id=9500"
echo "## 4. Write on standby (should be refused: standby is read-only)"; $S -c "update shop.products set stock_qty=0 where product_id=9500" 2>&1
echo "## 5. Failover: promote standby, then write to it"
pg_ctl -D /Users/mac/pgstandby promote -w >/dev/null; sleep 1
$S -c "select pg_is_in_recovery() as still_standby"
$S -c "update shop.products set stock_qty=7 where product_id=9500 returning product_id, stock_qty"
echo "## 6. Divergence: the old primary does NOT see the write made on the promoted node"
$P -c "select product_id, stock_qty from shop.products where product_id=9500"
