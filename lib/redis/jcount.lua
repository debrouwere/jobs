local board, schedule, registry
do
  local _obj_0 = KEYS
  board, schedule, registry = _obj_0[1], _obj_0[2], _obj_0[3]
end
local queues
do
  local _accum_0 = { }
  local _len_0 = 1
  local _list_0 = KEYS
  for _index_0 = 4, #_list_0 do
    local queue = _list_0[_index_0]
    _accum_0[_len_0] = queue
    _len_0 = _len_0 + 1
  end
  queues = _accum_0
end
local jobs = redis.call('hlen', board)
local scheduled = redis.call('zcard', schedule)
local runners = redis.call('hlen', registry)
local queued = { }
for _index_0 = 1, #queues do
  local queue = queues[_index_0]
  queued[queue] = redis.call('llen', queue)
end
return cjson.encode({
  jobs = jobs,
  runners = runners,
  scheduled = scheduled,
  queued = queued
})
