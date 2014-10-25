-- JREGISTER registry runner command
-- e.g. JREGISTER jobs:runners mytask mytaskrunner
--
-- keys: registry

{registry} = KEYS
{runner, command} = ARGV

redis.call 'hset', registry, runner, command
