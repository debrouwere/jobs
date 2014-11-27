local posix = require('posix')
local timing = require('utils/timing')
local dedent
dedent = function(s)
  s = string.gsub(s, '^%s*(.+)%s*$', '%1')
  s = string.gsub(s, '\n%s+', '\n')
  s = string.gsub(s, '\n*$', '')
  return s
end
local DECISECOND = 1000 * 1000 * 100
local forever
forever = function(f)
  local last = os.time()
  while true do
    local now = os.time()
    if now > last then
      last = now
      f()
    else
      posix.nanosleep(0, DECISECOND)
    end
  end
end
local copy
copy = function(t)
  local copied = { }
  for key, value in pairs(t) do
    copied[key] = value
  end
  return copied
end
local defaults
defaults = function(default, more)
  local options = copy(default)
  for key, value in pairs(more) do
    options[key] = value
  end
  return options
end
return {
  dedent = dedent,
  forever = forever,
  timing = timing,
  copy = copy,
  defaults = defaults
}
