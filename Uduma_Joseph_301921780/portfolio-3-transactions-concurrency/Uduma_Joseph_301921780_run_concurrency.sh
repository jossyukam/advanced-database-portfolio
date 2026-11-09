#!/bin/bash
# Usage: ./Uduma_Joseph_301921780_run_concurrency.sh   (set PSQL to your connection string if needed)
PSQL=${PSQL:-"psql -d shopdb -q"}
for mode in unsafe safe; do
  echo "=============== MODE: $mode (stock = 1 unit, two buyers at once) ==============="
  $PSQL -f Uduma_Joseph_301921780_setup_9002.sql
  $PSQL -f Uduma_Joseph_301921780_session_${mode}_A.sql &
  sleep 0.5
  $PSQL -f Uduma_Joseph_301921780_session_${mode}_B.sql &
  wait
  $PSQL -c "SELECT stock_qty FROM shop.products WHERE product_id=9002" -c "SELECT count(*) AS sales_recorded FROM shop.stock_log WHERE product_id=9002"
done
