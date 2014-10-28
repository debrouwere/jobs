-- Jobs reference low-level client library
-- (makes evalshas accessible as commands)

redis = require 'redis'

connect = (...) ->
    store = redis.connect ...
    commands = store\hgetall 'commands'
    for command, sha in pairs commands
        redis.commands[command] = redis.command command, {
            request: (client, command, ...) ->
                client.requests.multibulk client, 
                    'evalsha', sha, ...
        }

    -- whatever you add to redis.commands only
    -- gets added in for new clients
    return redis.connect ...


return connect