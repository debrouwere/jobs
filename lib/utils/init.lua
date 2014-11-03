local posix = require('posix')
local timing = require('lib/utils/timing')
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
return {
  dedent = dedent,
  forever = forever,
  timing = timing
}
