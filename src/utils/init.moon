posix = require 'posix'
timing = require 'utils/timing'

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

-- copy a table
copy = (t) ->
    copied = {}
    for key, value in pairs t
        copied[key] = value
    copied

-- defaults
defaults = (default, more) ->
    options = copy default
    for key, value in pairs more
        options[key] = value
    options

return {:dedent, :forever, :timing, :copy, :defaults}
