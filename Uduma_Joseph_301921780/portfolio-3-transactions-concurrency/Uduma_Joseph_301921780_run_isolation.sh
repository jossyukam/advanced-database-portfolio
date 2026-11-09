#!/bin/bash
PSQL=${PSQL:-"psql -d shopdb -q"}
for f in Uduma_Joseph_301921780_reader_READ_COMMITTED.sql Uduma_Joseph_301921780_reader_REPEATABLE_READ.sql; do
  echo "=============== $f ==============="
  $PSQL -f Uduma_Joseph_301921780_setup_9003.sql
  $PSQL -f $f &
  sleep 1
  $PSQL -f Uduma_Joseph_301921780_writer.sql      # commits price change while reader is mid-transaction
  wait
done
