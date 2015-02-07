-- JCOUNT board schedule [queue...]

{board, schedule, registry} = KEYS
queues = [queue for queue in *KEYS[4,]]

-- the amount of jobs and schedules should be equal, as expired
-- jobs are removed from both schedule and board, but given that 
-- one of JCOUNT's uses is for debugging, we include both numbers
jobs = redis.call 'hlen', board
scheduled = redis.call 'zcard', schedule
runners = redis.call 'hlen', registry

queued = {}
for queue in *queues
   queued[queue] = redis.call 'llen', queue

cjson.encode {:jobs, :runners, :scheduled, :queued}
