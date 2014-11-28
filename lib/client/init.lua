local cjson = require('cjson')
local initialize = require('initialize')
local connect = require('client/connect')
local utils = require('utils/init')
local parse
parse = function(str, format)
  if format == nil then
    format = 'plain'
  end
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
    listen = function(self, ...)
      local format, listener
      local arguments = {
        ...
      }
      local _exp_0 = #arguments
      if 1 == _exp_0 then
        format = 'plain'
        listener = arguments[1]
      elseif 2 == _exp_0 then
        format, listener = arguments[1], arguments[2]
      else
        error('listen takes two arguments: format and listener')
      end
      return utils.forever(function()
        local popped = self:pop(format)
        if popped then
          return listener(popped)
        end
      end)
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
      local now = os.time()
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
      local interval = utils.timing.seconds(schedule)
      if schedule["repeat"] then
        error('not implemented yet')
      end
      if schedule.duration then
        schedule.start = schedule.start or now
        schedule.stop = schedule.start + (tonumber(schedule.duration))
      end
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
      if format == nil then
        format = 'plain'
      end
      local meta = self.client:jget(1, self.keys.board, id)
      return parse(meta, format)
    end,
    dump = function(self)
      local runners = self.client:hgetall(self.keys.registry)
      local jobs = self.client:hgetall(self.keys.board)
      local out = { }
      out.runners = runners
      out.jobs = { }
      for id, serialized_meta in pairs(jobs) do
        local meta = cjson.decode(serialized_meta)
        out.jobs[id] = meta
      end
      return out
    end,
    load = function(self, board)
      self.client:hmset(self.keys.registry, board.runners)
      local jobs = { }
      for id, meta in pairs(jobs) do
        jobs[id] = cjson.encode(meta)
      end
      return self.client:hmset(self.keys.board, jobs)
    end,
    remove = function(self, id)
      local n_removed = self.client:jdel(2, self.keys.board, self.keys.schedule, id)
      return tonumber(n_removed)
    end,
    register = function(self, runner, command)
      return self.client:jregister(1, self.keys.registry, runner, command)
    end,
    get_queue = function(self, name)
      return Queue(name, self)
    end,
    get_queues = function(self)
      local list = { }
      local runners = self.client:hgetall(self.keys.registry)
      for runner, command in pairs(runners) do
        table.insert(list, (self:get_queue(runner)))
      end
      return list
    end,
    tick = function(self, options)
      if options == nil then
        options = { }
      end
      local now = options.now or os.time()
      local queues
      do
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = self:get_queues()
        for _index_0 = 1, #_list_0 do
          local queue = _list_0[_index_0]
          _accum_0[_len_0] = queue.key
          _len_0 = _len_0 + 1
        end
        queues = _accum_0
      end
      if options.trim then
        local keep = self:trim(options.trim, unpack(queues))
      end
      local n_queues = #queues
      local n_keys = n_queues + 2
      table.insert(queues, now)
      self.client:jtick(n_keys, self.keys.board, self.keys.schedule, unpack(queues))
      return n_queues
    end,
    trim = function(self, n, ...)
      if n == nil then
        n = -1
      end
      local queues = {
        ...
      }
      if #queues > 0 then
        queues = utils.copy(queues)
      else
        do
          local _accum_0 = { }
          local _len_0 = 1
          local _list_0 = self:get_queues()
          for _index_0 = 1, #_list_0 do
            local queue = _list_0[_index_0]
            _accum_0[_len_0] = queue.key
            _len_0 = _len_0 + 1
          end
          queues = _accum_0
        end
      end
      local n_queues = #queues
      table.insert(queues, n)
      return self.client:jtrim(n_queues, unpack(queues))
    end,
    respond = function(self, queue, command)
      queue = self:get_queue(queue)
      local inline = string.match(command, '{payload}')
      local stdin = not inline
      if inline then
        local payload
        do
          local _obj_0 = cjson.decode(meta)
          payload = _obj_0[1]
        end
        command = string.gsub(command, '{payload}', payload)
      end
      return queue:listen(function(meta)
        if stdin then
          local process = io.popen(command, 'w')
          process:write(meta)
          return process:close()
        else
          return os.execute(command)
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
  initialize = initialize,
  redis = {
    connect = connect
  },
  Board = Board,
  Queue = Queue
}
