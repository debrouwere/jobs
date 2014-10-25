-- JPOP queue
-- e.g. JPOP jobs:queue:shell
-- 
-- keys: queue

-- TODO: optional acknowledgements/retries
-- using RPOPLPUSH or a similar technique

{queue} = KEYS

redis.call 'rpop', queue
