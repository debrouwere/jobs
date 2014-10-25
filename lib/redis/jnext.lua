local DAY = 1000 * 60 * 60 * 24
local bin
bin = function(value, granularity)
  return math.ceil(value / granularity)
end
local tick
tick = function(last_run, interval, now, lambda, step)
  if lambda == nil then
    lambda = 1
  end
  if step == nil then
    step = DAY
  end
  if lambda ~= 1 then
    local age = now - start
    local n = bin(age, granularity)
    local multiplier = math.pow(n, lambda)
    interval = interval * multiplier
  end
  return last_run + interval
end
local board, schedule
do
  local _obj_0 = KEYS
  board, schedule = _obj_0[1], _obj_0[2]
end
local id, now
do
  local _obj_0 = ARGV
  id, now = _obj_0[1], _obj_0[2]
end
local serialized_job = redis.call('hget', board, id)
local runner, payload, interval, start, stop, lambda, step
do
  local _obj_0 = cjson.decode(serialized_job)
  runner, payload, interval, start, stop, lambda, step = _obj_0.runner, _obj_0.payload, _obj_0.interval, _obj_0.start, _obj_0.stop, _obj_0.lambda, _obj_0.step
end
local next_run = redis.call('zscore', schedule, id)
if next_run < now then
  local _ = next_run
else
  if start <= now and now < stop then
    next_run = tick(next_run, interval, now, lambda, step)
    redis.call('zadd', schedule, next_run, id)
  else
    next_run = -1
    redis.call('zrem', schedule, id)
  end
end
return next_run
