local jnext = redis.call('hget', 'commands', 'jnext')
local board, schedule, registry
do
  local _obj_0 = KEYS
  board, schedule, registry = _obj_0[1], _obj_0[2], _obj_0[3]
end
local id, runner, payload, interval, start, stop, lambda, step
do
  local _obj_0 = ARGV
  id, runner, payload, interval, start, stop, lambda, step = _obj_0[1], _obj_0[2], _obj_0[3], _obj_0[4], _obj_0[5], _obj_0[6], _obj_0[7], _obj_0[8]
end
local meta = {
  id = id,
  runner = runner,
  payload = payload,
  interval = interval,
  start = start,
  stop = stop,
  lambda = lambda,
  step = step
}
local serialized_meta = cjson.encode(meta)
redis.call('hset', board, id, serialized_meta)
return redis.call('hset', registry, runner, "jobs-" .. tostring(runner) .. "-runner")
