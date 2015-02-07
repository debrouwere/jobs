local queues = KEYS
local keep = ARGV[1] or 0
local trimmed = 0
for _index_0 = 1, #queues do
  local queue = queues[_index_0]
  local length = redis.call('llen', queue)
  local excess = math.max(0, length - keep)
  trimmed = trimmed + excess
  redis.call('ltrim', queue, 0, (keep - 1))
end
return trimmed
