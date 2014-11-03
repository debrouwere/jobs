-- JTICK board schedule queue [queue...] now
-- e.g. JTICK jobs jobs:schedule jobs:queue:shell jobs:queue:customrunner 1414139992
-- 
-- keys: board, schedule, queue
-- 
-- If you'd like to do a tick for all jobs regardless of 
-- runner, first do HKEYS registry (e.g. HKEYS jobs:runners)
-- and then use that to construct the appropriate
-- JTICK command or commands.


{board, schedule} = KEYS
queues = [queue for queue in *KEYS[3,]]
{now} = ARGV

jobs = redis.call 'zrangebyscore', schedule, 0, now

filters = {}
for queue in *queues
    name = string.match queue, '.+:(.+)$'
    filters[name] = queue

pushed = 0

for id in *jobs
    meta = redis.call 'hget', board, id
    {:runner} = cjson.decode meta

    if queue = filters[runner]
        -- right now queues are lists; this 
        -- has the advantage that jobs don't 
        -- disappear but the disadvantage that
        -- when a runner gets behind or 
        -- crashes, jobs will keep piling up
        redis.call 'lpush', queue, meta

        KEYS = KEYS
        ARGV = {now, id}

        require 'jnext'

        pushed += 1

pushed
