local cjson = require('cjson')
local connect = require('lib/client/connect')
local timing = require('lib/utils/timing')
local parse
parse = function(str, format)
  if (type(str)) == 'string' then
    local _exp_0 = format
    if 'json' == _exp_0 then
      str = cjson.decode(str)
    elseif 'plain' == _exp_0 then
      str = str
    else
      error("unsupported format: got " .. tostring(format) .. ", expected json or plain")
    end
  end
  return str
end
local Queue
do
  local _base_0 = {
    pop = function(self, format)
      if format == nil then
        format = 'plain'
      end
      local meta = self.client:jpop(1, self.key)
      return parse(meta, format)
    end,
    listen = function(self)
      local format, listener
      local _exp_0 = #args
      if 1 == _exp_0 then
        format = 'plain'
        do
          local _obj_0 = args
          listener = _obj_0[1]
        end
      elseif 2 == _exp_0 then
        do
          local _obj_0 = args
          format, listener = _obj_0[1], _obj_0[2]
        end
      else
        error('listen takes two arguments: format and listener')
      end
      local last = os.time()
      while true do
        local now = os.time()
        if now > last then
          last = now
          local popped = self:pop(format)
          if popped then
            listener(popped)
          end
        end
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, name, board)
      self.board = board
      self.client = self.board.client
      self.name = name
      self.key = self.board.keys.queue .. ":" .. name
    end,
    __base = _base_0,
    __name = "Queue"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Queue = _class_0
end
local Board
do
  local _base_0 = {
    put = function(self, id, runner, payload, schedule, options)
      if options == nil then
        options = { }
      end
      local nx = options.update == false
      local set
      if nx then
        do
          local _base_1 = self.client
          local _fn_0 = _base_1.jsetnx
          set = function(...)
            return _fn_0(_base_1, ...)
          end
        end
      else
        do
          local _base_1 = self.client
          local _fn_0 = _base_1.jset
          set = function(...)
            return _fn_0(_base_1, ...)
          end
        end
      end
      local interval = timing.seconds(schedule)
      if schedule["repeat"] then
        error('not implemented yet')
      end
      if schedule.duration then
        error('not implemented yet')
      end
      local now = os.time()
      local next_run = set(3, self.keys.board, self.keys.schedule, self.keys.registry, now, id, runner, payload, interval, schedule.start, schedule.stop, schedule.lambda, schedule.step)
      return tonumber(next_run)
    end,
    create = function(self, ...)
      return self:put(..., {
        update = false
      })
    end,
    schedule = function(self, id, runner, payload)
      return error('not implemented yet')
    end,
    show = function(self, id, format)
      local meta = self.client:jget(1, self.keys.board, id)
      return parse(meta, format)
    end,
    remove = function(self, id)
      local n_removed = self.client:jdel(2, self.keys.board, self.keys.schedule, id)
      return tonumber(n_removed)
    end,
    register = function(self, runner, command)
      return self.client:jregister(1, self.keys.registry, runner, command)
    end,
    queue = function(self, name)
      return Queue(name, self)
    end,
    tick = function(self, now)
      now = now or os.time()
      local runners = self.client:hgetall(self.keys.registry)
      local queues = { }
      for runner, command in pairs(runners) do
        table.insert(queues, (self:queue(runner)).key)
      end
      local n_queues = #queues
      local n_keys = n_queues + 2
      table.insert(queues, now)
      self.client:jtick(n_keys, self.keys.board, self.keys.schedule, unpack(queues))
      return n_queues
    end,
    respond = function(queue, command)
      queue = self:queues(queue)
      return queue:listen(function(meta)
        if string.match(command, '{payload}') then
          command = string.gsub(command, '{payload}', payload)
          return os.execute(command)
        else
          command = io.popen(command, 'w')
          return command:write(meta)
        end
      end)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, name, ...)
      if name == nil then
        name = 'jobs'
      end
      self.name = name
      self.key = name
      self.keys = {
        board = self.key,
        schedule = self.key .. ":schedule",
        queue = self.key .. ":queue",
        registry = self.key .. ":runners"
      }
      self.client = connect(...)
    end,
    __base = _base_0,
    __name = "Board"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Board = _class_0
end
return {
  redis = {
    connect = connect
  },
  Board = Board,
  Queue = Queue
}
