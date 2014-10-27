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
    do
      local _obj_0 = KEYS
      board, schedule = _obj_0[1], _obj_0[2]
    end
    do
      local _obj_0 = ARGV
      now, id = _obj_0[1], _obj_0[2]
    end
    now = tonumber(now)
    local serialized_job = redis.call('hget', board, id)
    local payload, interval, start, stop, lambda, step
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
    pushed = pushed + 1
  end
end
return pushed
