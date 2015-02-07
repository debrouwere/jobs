queues = KEYS
keep = ARGV[1] or 0

trimmed = 0

for queue in *queues
    length = redis.call 'llen', queue
    excess = math.max(0, length - keep)
    trimmed += excess
    -- to trim to n items, we retain [0, n-1]
    redis.call 'ltrim', queue, 0, (keep - 1)

trimmed