local argparse = require('argparse')
local jobs = require('lib/client/init')
local initialize = require('lib/init')
local utils = require('lib/utils/init')
local parser = argparse()
do
  parser:name('job')
  parser:description(utils.dedent([[        Jobs is a next-generation cron.
    ]]))
end
local show = parser:command('show'):description('show job details')
local remove = parser:command('remove'):description('remove a job')
local create = parser:command('create'):description('create a job but do not update if it already exists')
local put = parser:command('put'):description('create or update a job')
local respond = parser:command('respond'):description('listen to tasks of a specific type')
local init = parser:command('init'):description('initialize redis with jobs extensions (administrative)')
local tick = parser:command('tick'):description('put jobs that need to run on the queue (administrative)')
local _list_0 = {
  show,
  remove
}
for _index_0 = 1, #_list_0 do
  local command = _list_0[_index_0]
  do
    command:argument('name')
  end
end
local _list_1 = {
  create,
  put
}
for _index_0 = 1, #_list_1 do
  local command = _list_1[_index_0]
  do
    command:argument('name'):description('A job identifier; can be any string.')
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
  respond:argument('type'):description('What type of job to respond to.')
  respond:argument('executable'):description('The responding executable.')
end
local arguments = parser:parse()
local board = jobs.Board()
if arguments.init or arguments.tick then
  local commands = initialize()
  print('Loading Jobs commands into Redis.\n')
  print('Loaded:\n')
  for name, sha in pairs(commands) do
    print("  " .. tostring(name) .. "    \t(" .. tostring(sha) .. ")")
  end
  print('')
end
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
  return board:put(arguments.name, arguments.runner, arguments.payload, arguments, options)
else
  if arguments.show then
    return print(board:show(arguments.name))
  else
    if arguments.remove then
      return board:remove(arguments.name)
    else
      if arguments.respond then
        return board:respond(arguments.type, arguments.executable)
      else
        if arguments.tick then
          print('Starting the job clock.')
          return utils.forever((function()
            local _base_0 = board
            local _fn_0 = _base_0.tick
            return function(...)
              return _fn_0(_base_0, ...)
            end
          end)())
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
