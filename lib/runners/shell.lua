local cjson = require('cjson')
local input = io.read("*all")
local params = cjson:decode(input)
local payload
payload = params[1]
local output, err = os.execute(payload)
return io.write(output)
