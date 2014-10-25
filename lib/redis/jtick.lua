local jnext = redis.call('hget', 'commands', 'jnext')
local board, schedule
do
  local _obj_0 = KEYS
  board, schedule = _obj_0[1], _obj_0[2]
end
local queues
do
  local _accum_0 = { }
  local _len_0 = 1
  local _list_0 = KEYS
  for _index_0 = 3, #_list_0 do
    local queue = _list_0[_index_0]
    _accum_0[_len_0] = queue
    _len_0 = _len_0 + 1
  end
  queues = _accum_0
end
local now
do
  local _obj_0 = ARGV
  now = _obj_0[1]
end
local jobs = redis.call('zrangebyscore', schedule, 0, now)
local filters = { }
for _index_0 = 1, #queues do
  local queue = queues[_index_0]
  local name = string.match(queue, '.+:(.+)$')
  filters[name] = queue
end
local pushed = 0
for _index_0 = 1, #jobs do
  local id = jobs[_index_0]
  local meta = redis.call('hget', board, id)
  local runner
  do
    local _obj_0 = cjson.decode(meta)
    runner = _obj_0.runner
  end
  if filters[runner] then
    redis.call('lpush', queue, meta)
    redis.call('evalsha', jnext, 2, board, schedule, id, now)
    pushed = pushed + 1
  end
end
return pushed
