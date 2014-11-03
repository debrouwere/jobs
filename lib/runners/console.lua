local cjson = require('cjson')
local input = io.read("*all")
local params = cjson.decode(input)
local payload
payload = params.payload
return print((os.date('%c')), payload)
