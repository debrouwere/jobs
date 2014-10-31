cjson = require 'cjson'

input = io.read "*all"
params = cjson\decode input
{payload} = params

output, err = os.execute payload
io.write output