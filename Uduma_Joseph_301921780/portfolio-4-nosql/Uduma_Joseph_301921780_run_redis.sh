#!/bin/bash
# Runs Uduma_Joseph_301921780_redis_cart_and_ranking.redis line by line (comments printed as headings), then the guarded Lua demo.
PORT=${REDIS_PORT:-6380}
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  if [[ "$line" == \#* ]]; then echo; echo "$line"; continue; fi
  echo "> $line"; redis-cli -p $PORT $line
done < Uduma_Joseph_301921780_redis_cart_and_ranking.redis

echo; echo "# --- Guarded decrement via Lua (Uduma_Joseph_301921780_guarded_decrement.lua): stock starts at 1, three buyers ---"
redis-cli -p $PORT SET stock:prod:9200 1
for buyer in 1 2 3; do
  echo -n "buyer $buyer -> "; redis-cli -p $PORT --eval Uduma_Joseph_301921780_guarded_decrement.lua stock:prod:9200
done
echo -n "final stock: "; redis-cli -p $PORT GET stock:prod:9200
