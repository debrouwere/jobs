-- JNEXT board schedule id now
-- e.g. JNEXT jobs jobs:schedule mytask 1414139992
--
-- keys: board, schedule


DAY = 1000 * 60 * 60 * 24

-- put continuous values into discrete bins
bin = (value, granularity) ->
    math.ceil value / granularity

-- lambda is the decay constant, 
--   e.g. lambda 2 will double the interval every step
-- step determines the scale, that is, 
--   after how many seconds do we go to a longer 
--   or shorter interval
tick = (last_run, interval, now, lambda=1, step=DAY) ->
    if lambda != 1
        age = now - start
        n = bin age, granularity
        multiplier = math.pow n, lambda
        interval = interval * multiplier

    last_run + interval

{board, schedule} = KEYS
{id, now} = ARGV
serialized_job = redis.call 'hget', board, id
{
    :runner, 
    :payload, 
    :interval,
    :start,
    :stop,
    :lambda,
    :step
} = cjson.decode serialized_job

next_run = redis.call 'zscore', schedule, id

if next_run < now
    next_run
else if start <= now and now < stop
    next_run = tick next_run, interval, now, lambda, step
    redis.call 'zadd', schedule, next_run, id
else
    next_run = -1
    redis.call 'zrem', schedule, id

next_run
