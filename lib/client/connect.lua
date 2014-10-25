local redis = require('redis')
local connect
connect = function(...)
  local store = redis.connect(...)
  local commands = store:hgetall('commands')
  for command, sha in pairs(commands) do
    redis.commands[command] = redis.command(command, {
      request = function(client, command, ...)
        return client.requests.multibulk(client, 'evalsha', sha, ...)
      end
    })
  end
  return redis.connect(...)
end
return connect
