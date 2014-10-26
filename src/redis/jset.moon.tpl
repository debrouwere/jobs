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
require 'jnext'
