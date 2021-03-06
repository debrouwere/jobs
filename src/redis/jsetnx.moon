-- JSETNX board schedule registry now id runner payload interval start stop lambda step
-- e.g. jobs jobs:schedule jobs:runners 1414139992 myjob shell 'echo hey' 5000
--
-- keys: board, schedule, registry
--
-- create a new job, but don't update the job it already exists


{board} = KEYS
{now, id} = ARGV

if (redis.call 'hexists', board, id) == 1
    0
else 

    -- START INLINED jset --
    -- JSET board schedule registry now id runner payload interval start stop lambda step
    -- e.g. jobs jobs:schedule jobs:runners 1414139992 myjob shell 'echo hey' 5000
    --
    -- keys: board, registry


    {board, schedule, registry} = KEYS
    {now, id, runner, payload, interval, start, stop, lambda, step} = ARGV
    now = tonumber now
    start = tonumber (start or now)
    interval = tonumber interval

    meta = {:id, :runner, :payload, :interval, :start, :stop, :lambda, :step}

    serialized_meta = cjson.encode meta
    redis.call 'hset', board, id, serialized_meta
    redis.call 'hset', registry, runner, "jobs-#{runner}-runner"

    KEYS = {board, schedule}
    ARGV = {now, id}

    -- START INLINED jnext --
    -- JNEXT board schedule now id
    -- e.g. JNEXT jobs jobs:schedule 1414139992 mytask
    --
    -- keys: board, schedule


    DAY = 1000 * 60 * 60 * 24

    -- put continuous values into discrete bins
    bin = (value, granularity) ->
        math.floor value / granularity

    -- lambda is the decay constant, 
    --   e.g. lambda 2 will double the interval every step
    -- step determines the scale, that is, 
    --   after how many seconds do we go to a longer 
    --   or shorter interval
    tick = (start, last_run, now, interval, lambda=1, step=DAY) ->
        if lambda != 1
            age = now - start
            n = bin age, step
            multiplier = math.pow lambda, n
            interval = interval * multiplier

        -- while the desired behavior can differ depending 
        -- on job type, generally we want to catch up on 
        -- jobs that are behind by only scheduling things
        -- in the future
        skips = math.floor (now - last_run) / interval
        skips = math.max 1, skips
        last_run + skips * interval

    -- this script can also be run as an include
    -- from within `jset`, `jsetnx` and `jtick`, 
    -- in which case these arguments are already
    -- present
    {board, schedule} = KEYS
    {now, id} = ARGV

    now = tonumber now

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

    stop = stop or math.huge
    next_run = redis.call 'zscore', schedule, id
    if next_run then next_run = tonumber next_run

    future = (next_run or 0) > now
    expired = now >= (tonumber stop)
    new = next_run == false

    if future
        next_run
    else
        if expired
            next_run = -1
            redis.call 'zrem', schedule, id
            redis.call 'hdel', board, id
        else
            if new
                next_run = start
                redis.call 'zadd', schedule, next_run, id
            else
                last_run = next_run
                next_run = tick start, last_run, now, interval, lambda, step
                redis.call 'zadd', schedule, next_run, id

    next_run
    -- END INLINED jnext --

    1-- END INLINED jset --

