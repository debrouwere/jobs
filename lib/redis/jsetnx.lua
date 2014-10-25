local board, registry
do
  local _obj_0 = KEYS
  board, registry = _obj_0[1], _obj_0[2]
end
local id
do
  local _obj_0 = ARGV
  id = _obj_0[1]
end
local options
do
  local _accum_0 = { }
  local _len_0 = 1
  local _list_0 = ARGV
  for _index_0 = 2, #_list_0 do
    local option = _list_0[_index_0]
    _accum_0[_len_0] = option
    _len_0 = _len_0 + 1
  end
  options = _accum_0
end
if redis.call('hexists', board, id) then
  return 0
else
  local jset = redis.call('hget', 'commands', 'jset')
  return redis.call('evalsha', jset, 2, board, registry, id, (unpack(options)))
end
