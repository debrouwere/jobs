local cjson = require('cjson')
local yaml = require('yaml')
local argparse = require('argparse')
local jobs = require('client/init')
local utils = require('utils/init')
local parser = argparse()
do
  parser:name('job')
  parser:description(utils.dedent([[        Jobs is a next-generation cron.
    ]]))
end
local show = parser:command('show'):description('show job details')
local dump = parser:command('dump'):description('dump a representation of the entire job board')
local remove = parser:command('remove'):description('remove a job')
local create = parser:command('create'):description('create a job but do not update if it already exists')
local put = parser:command('put'):description('create or update a job')
local respond = parser:command('respond'):description('listen to tasks of a specific type')
local init = parser:command('init'):description('initialize redis with jobs extensions (administrative)')
local tick = parser:command('tick'):description('put jobs that need to run on the queue (administrative)')
local _list_0 = {
  show,
  dump,
  remove,
  create,
  put,
  respond,
  init,
  tick
}
for _index_0 = 1, #_list_0 do
  local command = _list_0[_index_0]
  do
    command:option('-H', '--host'):description('the ip address to Redis')
    command:option('-P', '--port'):description('the port to Redis')
    command:flag('-S', '--stdin'):description('accept configuration over standard input')
  end
end
local _list_1 = {
  show,
  dump
}
for _index_0 = 1, #_list_1 do
  local command = _list_1[_index_0]
  do
    command:option('-f', '--format'):description('the format to output to (yaml, json)'):default('yaml')
  end
end
local _list_2 = {
  show,
  remove
}
for _index_0 = 1, #_list_2 do
  local command = _list_2[_index_0]
  do
    command:argument('id')
  end
end
local _list_3 = {
  create,
  put
}
for _index_0 = 1, #_list_3 do
  local command = _list_3[_index_0]
  do
    command:argument('id'):description('A job identifier; can be any string.')
    command:argument('runner'):description('Which job runner to use, e.g. shell.')
    command:argument('payload'):description('What to pass to the runner.')
    command:option('-s', '--seconds'):description('Run the job every <seconds> seconds.')
    command:option('-m', '--minutes'):description('Run the job every <minutes> minutes.')
    command:option('-h', '--hours'):description('Run the job every <hours> hours.')
    command:option('-d', '--days'):description('Run the job every <days> days.')
    command:option('-w', '--weeks'):description('Run the job every <weeks> weeks.')
    command:option('-M', '--months'):description('Run the job every <months> months.')
    command:option('-q', '--quarters'):description('Run the job every <quarters> quarters.')
    command:option('-y', '--years'):description('Run the job every <years> years.')
    command:option('-l', '--lambda'):description('Grow or shrink the interval over time.')
    command:option('-x', '--step'):description('After what interval to apply lambda.')
    command:option('-f', '--from'):description('Run the job starting at <from> timestamp.')
    command:option('-u', '--until'):description('Remove the job after <until> timestamp.')
    command:option('-D', '--duration'):description('Remove the job after <duration> seconds.')
    command:option('-r', '--repeat'):description('Remove the job after <repeat> runs.')
  end
end
do
  tick:option('-t', '--trim', 'Retain at most <n> queued jobs before ticking, to avoid jobs piling up.')
end
do
  respond:argument('type'):description('What type of job to respond to.')
  respond:argument('executable'):description('The responding executable.')
end
local execute
execute = function(host, port, arguments)
  if arguments.init or arguments.tick then
    local commands = jobs.initialize(host, port)
    print('Loading Jobs commands into Redis.\n')
    print('Loaded:\n')
    for name, sha in pairs(commands) do
      print("  " .. tostring(name) .. "    \t(" .. tostring(sha) .. ")")
    end
    print('')
  end
  local board = jobs.Board('jobs', host, port)
  if arguments.create or arguments.put then
    local update
    if arguments.create then
      update = false
    else
      update = true
    end
    local options = {
      update = update
    }
    return board:put(arguments.id, arguments.runner, arguments.payload, arguments, options)
  else
    if arguments.show then
      local meta = board:show(arguments.id)
      local _exp_0 = arguments.format
      if 'json' == _exp_0 then
        return print(meta)
      elseif 'yaml' == _exp_0 then
        meta = cjson.decode(meta)
        return print(yaml.dump(meta))
      else
        return error('format should be one of: yaml, json')
      end
    else
      if arguments.dump then
        dump = board:dump()
        local _exp_0 = arguments.format
        if 'json' == _exp_0 then
          return print(cjson.encode(dump))
        elseif 'yaml' == _exp_0 then
          return print(yaml.dump(dump))
        else
          return error('format should be one of: yaml, json')
        end
      else
        if arguments.remove then
          return board:remove(arguments.id)
        else
          if arguments.respond then
            print("Responding to " .. tostring(arguments.type) .. " jobs.")
            return board:respond(arguments.type, arguments.executable)
          else
            if arguments.tick then
              print('Starting the job clock.')
              local trim = arguments.trim or (os.getenv('JOBS_QUEUE_TRIM'))
              local heartbeat
              heartbeat = function(meta)
                local timestamp, queued, queues, trimmed
                timestamp, queued, queues, trimmed = meta.timestamp, meta.queued, meta.queues, meta.trimmed
                local dt = os.date("!%Y-%m-%d %T", timestamp)
                return print("[" .. tostring(dt) .. "] Queued " .. tostring(queued) .. " jobs onto " .. tostring(#queues) .. " queues. Trimmed " .. tostring(trimmed) .. " jobs from the queue.")
              end
              return utils.forever((function()
                local _base_0 = board
                local _fn_0 = _base_0.tick
                return function(...)
                  return _fn_0(_base_0, ...)
                end
              end)(), {
                trim = trim,
                heartbeat = heartbeat
              })
            else
              if arguments.register then
                return error('not implemented yet')
              else
                if arguments.board then
                  return error('not implemented yet')
                else
                  if arguments.pop then
                    return error('not implemented yet')
                  else
                    if arguments.next then
                      return error('not implemented yet')
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
local arguments = parser:parse()
local host = arguments.host or (os.getenv('JOBS_REDIS_HOST')) or '127.0.0.1'
local port = arguments.port or (os.getenv('JOBS_REDIS_PORT')) or '6379'
if arguments.stdin then
  for input in io.lines() do
    local options = utils.defaults(arguments, (cjson.decode(input)))
    execute(board, options)
  end
else
  return execute(host, port, arguments)
end
