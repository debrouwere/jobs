local registry
do
  local _obj_0 = KEYS
  registry = _obj_0[1]
end
local runner, command
do
  local _obj_0 = ARGV
  runner, command = _obj_0[1], _obj_0[2]
end
return redis.call('hset', registry, runner, command)
