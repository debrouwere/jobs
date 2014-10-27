local board
do
  local _obj_0 = KEYS
  board = _obj_0[1]
end
local now, id
do
  local _obj_0 = ARGV
  now, id = _obj_0[1], _obj_0[2]
end
if (redis.call('hexists', board, id)) ~= 0 then
  return 0
else
  local schedule, registry
  do
    local _obj_0 = KEYS
    board, schedule, registry = _obj_0[1], _obj_0[2], _obj_0[3]
  end
  local runner, payload, interval, start, stop, lambda, step
  do
    local _obj_0 = ARGV
    now, id, runner, payload, interval, start, stop, lambda, step = _obj_0[1], _obj_0[2], _obj_0[3], _obj_0[4], _obj_0[5], _obj_0[6], _obj_0[7], _obj_0[8], _obj_0[9]
  end
  now = tonumber(now)
  start = tonumber((start or now))
  interval = tonumber(interval)
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
  redis.call('hset', registry, runner, "jobs-" .. tostring(runner) .. "-runner")
  local KEYS = {
    board,
    schedule
  }
  local ARGV = {
    now,
    id
  }
  local DAY = 1000 * 60 * 60 * 24
  local bin
  bin = function(value, granularity)
    return math.floor(value / granularity)
  end
  local tick
  tick = function(start, last_run, now, interval, lambda, step)
    if lambda == nil then
      lambda = 1
    end
    if step == nil then
      step = DAY
    end
    if lambda ~= 1 then
      local age = now - start
      local n = bin(age, step)
      local multiplier = math.pow(lambda, n)
      interval = interval * multiplier
    end
    return last_run + interval
  end
  board, schedule = KEYS[1], KEYS[2]
  now, id = ARGV[1], ARGV[2]
  now = tonumber(now)
  local serialized_job = redis.call('hget', board, id)
  do
    local _obj_0 = cjson.decode(serialized_job)
    runner, payload, interval, start, stop, lambda, step = _obj_0.runner, _obj_0.payload, _obj_0.interval, _obj_0.start, _obj_0.stop, _obj_0.lambda, _obj_0.step
  end
  stop = stop or math.huge
  local next_run = redis.call('zscore', schedule, id)
  if next_run then
    next_run = tonumber(next_run)
  end
  local future = (next_run or 0) > now
  local expired = now >= stop
  local new = next_run == false
  if future then
    local _ = next_run
  else
    if expired then
      next_run = -1
      redis.call('zrem', schedule, id)
      redis.call('hdel', board, id)
    else
      if new then
        next_run = start
        redis.call('zadd', schedule, next_run, id)
      else
        local last_run = next_run
        next_run = tick(start, last_run, now, interval, lambda, step)
        redis.call('zadd', schedule, next_run, id)
      end
    end
  end
  local _ = next_run
  return 1
end
