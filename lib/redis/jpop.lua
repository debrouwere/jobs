local queue
do
  local _obj_0 = KEYS
  queue = _obj_0[1]
end
return redis.call('rpop', queue)
