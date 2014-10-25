local argparse = require('argparse')
local client = require('client')
do
  local parser = argparse()
  parser:name('runner')
  parser:description('tk')
  parser:option('-t', '--type')
end
local args = parser:parse()
local queue = client.queues[runner]
local payload = queue.pop('json')
if string.match(command, '{payload}') then
  string.gsub(command, '{payload}', payload)
  return os.execute()
else
  return os.pipe()
end
