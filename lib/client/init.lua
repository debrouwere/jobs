local connect = require('src/client/connect')
local timing = require('src/utils/timing')
local Queue
do
  local _base_0 = {
    pop = function(self, format)
      if format == nil then
        format = 'plain'
      end
      local payload = redis:jpop(self.key)
      local _exp_0 = format
      if 'json' == _exp_0 then
        return cjson.decode(payload)
      else
        return payload
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, name, board)
      self.board = board
      self.name = name
      self.key = self.board.keys.queue + ":" + name
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
      return set(3, self.keys.board, self.keys.schedule, self.keys.registry, id, runner, payload, interval, schedule.start, schedule.stop, schedule.lambda, schedule.step)
    end,
    create = function(self, ...)
      return self:put(..., {
        update = false
      })
    end,
    show = function(self, id)
      return self.client:jget(1, self.keys.board, id)
    end,
    remove = function(self, id)
      return self.client:jdel(2, self.keys.board, self.keys.schedule, id)
    end,
    register = function(self, runner, command)
      return self.client:jregister(1, self.keys.registry, runner, command)
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
  Board = Board
}
