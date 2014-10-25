local board
do
  local _obj_0 = KEYS
  board = _obj_0[1]
end
local id
do
  local _obj_0 = ARGV
  id = _obj_0[1]
end
return redis.call('hget', board, id)
