local lfs = require('lfs')
local redis = require('redis')
local scriptfiles = { }
local scripts = { }
local commands = { }
local source = debug.getinfo(1).source
local here = string.match(source, '^@(.+)/.+$')
local commands_directory = tostring(here) .. "/../lib/redis"
for file in lfs.dir(commands_directory) do
  do
    local name = string.match(file, '(.+)\.lua$')
    if name then
      table.insert(scriptfiles, name)
    end
  end
end
for _index_0 = 1, #scriptfiles do
  local name, filename = scriptfiles[_index_0]
  local file = io.open(tostring(commands_directory) .. "/" .. tostring(name) .. ".lua")
  table.insert(scripts, file:read('*all'))
  file:close()
end
local store = redis.connect('127.0.0.1', 6379)
local evalshas = store:pipeline(function(pipeline)
  for i, script in ipairs(scripts) do
    pipeline:script('load', script)
  end
end)
for i, sha in ipairs(evalshas) do
  local name = scriptfiles[i]
  commands[name] = sha
end
store:del('commands')
for name, sha in pairs(commands) do
  store:hset('commands', name, sha)
end
print('Loaded commands: ')
for name, sha in pairs(store:hgetall('commands')) do
  print(tostring(name) .. " (" .. tostring(sha) .. ")")
end