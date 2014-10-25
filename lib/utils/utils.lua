local dedent
dedent = function(s)
  s = string.gsub(s, '^%s*(.+)%s*$', '%1')
  s = string.gsub(s, '\n%s+', '\n')
  s = string.gsub(s, '\n*$', '')
  return s
end
return {
  dedent = dedent
}
