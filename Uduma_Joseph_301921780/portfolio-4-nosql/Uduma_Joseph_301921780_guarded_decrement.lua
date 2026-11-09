-- Atomically decrement stock only if at least 1 unit remains. Returns new stock, or -1 if out of stock.
local s = tonumber(redis.call('GET', KEYS[1]))
if s and s > 0 then
  return redis.call('DECR', KEYS[1])
else
  return -1
end
