posix = require 'posix'
timing = require 'lib/utils/timing'

-- trim and dedent
dedent = (s) ->
    s = string.gsub s, '^%s*(.+)%s*$', '%1'
    s = string.gsub s, '\n%s+', '\n'
    s = string.gsub s, '\n*$', ''
    s

DECISECOND = 1000 * 1000 * 100

-- repeat forever, but at most once a second, 
-- sleeping in between to avoid wasting 
-- too many CPU cycles
forever = (f) ->
    last = os.time()
    while true
        now = os.time()
        if now > last
            last = now
            f!
        else
            posix.nanosleep 0, DECISECOND

return {:dedent, :forever, :timing}