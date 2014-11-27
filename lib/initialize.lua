local lfs = require('lfs')
local redis = require('redis')
return function(...)
  local scriptfiles = { }
  local scripts = { }
  local evalshas = { }
  local commands = { }
  local source = debug.getinfo(1).source
  local here = string.match(source, '^@(.+)/.+$')
  local commands_directory = tostring(here) .. "/redis"
  for file in lfs.dir(commands_directory) do
    do
      local name = string.match(file, '(.+)%.lua$')
      if name then
        table.insert(scriptfiles, name)
      end
    end
  end
  for _index_0 = 1, #scriptfiles do
    local name = scriptfiles[_index_0]
    local file = io.open(tostring(commands_directory) .. "/" .. tostring(name) .. ".lua")
    table.insert(scripts, file:read('*all'))
    file:close()
  end
  local store = redis.connect(...)
  for _index_0 = 1, #scripts do
    local script = scripts[_index_0]
    local sha = store:script('load', script)
    table.insert(evalshas, sha)
  end
  for i, sha in ipairs(evalshas) do
    local name = scriptfiles[i]
    commands[name] = sha
  end
  store:del('commands')
  for name, sha in pairs(commands) do
    store:hset('commands', name, sha)
  end
  return store:hgetall('commands')
end
