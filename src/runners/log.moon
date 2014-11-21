lfs = require 'lfs'
cjson = require 'cjson'

input = io.read "*all"
params = cjson.decode input
{:payload} = params

-- lfs.currentdir() .. '/jobs.log'
destination = '/var/log/jobs/jobs.log'
log = io.open destination, 'a'
date = (os.date '%c')
entry = "#{date} #{payload}\n"
log\write entry
log\close!