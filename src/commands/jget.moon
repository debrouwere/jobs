-- JGET board id
-- e.g. JGET jobs myjob
--
-- keys: board

{board} = KEYS
{id} = ARGV

redis.call 'hget', board, id
