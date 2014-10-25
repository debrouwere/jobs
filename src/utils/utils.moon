-- trim and dedent
dedent = (s) ->
    s = string.gsub s, '^%s*(.+)%s*$', '%1'
    s = string.gsub s, '\n%s+', '\n'
    s = string.gsub s, '\n*$', ''
    s

return {:dedent}