-- JDEL board [schedule] id
-- e.g. JDEL jobs jobs:schedule myjob
--
-- keys: board, schedule
--
-- if schedule is not specified, the 
-- job is only deleted after the 
-- next run

{board, schedule} = KEYS
{id} = ARGV

if schedule
    redis.call 'zrem', schedule, id

redis.call 'hdel', board, id
