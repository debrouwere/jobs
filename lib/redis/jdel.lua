local board, schedule
do
  local _obj_0 = KEYS
  board, schedule = _obj_0[1], _obj_0[2]
end
local id
do
  local _obj_0 = ARGV
  id = _obj_0[1]
end
if schedule then
  redis.call('zrem', schedule, id)
end
return redis.call('hdel', board, id)
