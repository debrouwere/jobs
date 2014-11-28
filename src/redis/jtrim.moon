queues = KEYS
keep = ARGV[1] or 0

for queue in *queues
    -- to trim to n items, we retain [0, n-1]
    redis.call 'ltrim', queue, 0, (keep - 1)

#queues