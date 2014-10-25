local argparse = require('argparse')
local jobs = require('src/client/init')
local utils = require('src/utils/utils')
local timing = require('src/utils/timing')
local parser = argparse()
do
  parser:name('jobs')
  parser:description(utils.dedent([[        Hello there chaps!
        Here's a sort of description of sorts.
    ]]))
end
local show = parser:command('show')
local remove = parser:command('remove')
local create = parser:command('create')
local put = parser:command('put')
local tick = parser:command('tick')
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
local arguments = parser:parse()
local board = jobs.Board()
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
      if arguments.tick then
        return error('not implemented yet')
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
