local queues = KEYS
local keep = ARGV[1] or 0
for _index_0 = 1, #queues do
  local queue = queues[_index_0]
  redis.call('ltrim', queue, 0, (keep - 1))
end
return #queues
