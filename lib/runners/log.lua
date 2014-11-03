local lfs = require('lfs')
local cjson = require('cjson')
local input = io.read("*all")
local params = cjson.decode(input)
local payload
payload = params.payload
local destination = lfs.currentdir() .. '/jobs.log'
local log = io.open(destination, 'a')
local date = (os.date('%c'))
local entry = tostring(date) .. " " .. tostring(payload) .. "\n"
log:write(entry)
return log:close()
