-- Jobs reference low-level client library
-- (makes evalshas accessible as commands)
--
-- (a more advanced library would translate
-- a hash of options into a list of options,
-- obviating the need to remember the order
-- of arguments; it might also convert 
-- human-readable intervals into a seconds
-- integer)

redis = require 'redis'

jobs = {}

jobs.connect = (...) ->
    store = redis.connect ...
    commands = store\hgetall 'commands'
    for command, sha in pairs commands
        redis.commands[command] = redis.command command, {
            request: (client, command, ...) ->
                client.requests.multibulk client, 
                    'evalsha', sha, 0, ...
        }

    -- whatever you add to redis.commands only gets added 
    -- in for new clients
    return redis.connect ...

return jobs

