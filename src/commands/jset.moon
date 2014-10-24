-- JSET board registry id runner payload interval start stop lambda step
-- e.g. jobs jobs:runners myjob shell 'echo hey' 5000
--
-- keys: board, registry

jnext = redis.call 'hget', 'commands', 'jnext'


{board, registry} = KEYS
{id, runner, payload, interval, start, stop, lambda, step} = ARGV
meta = {:id, :runner, :payload, :interval, :start, :stop, :lambda, :step}

serialized_meta = cjson.encode meta
redis.call 'hset', board, id, serialized_meta
redis.call 'hset', registry, runner, "jobs-#{runner}-runner"
redis.call 'evalsha', jnext, 2, board, schedule, id
