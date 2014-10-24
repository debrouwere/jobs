jobs = require 'src/jobs'

-- TODO: for better testing, first do a flushdb
-- and then `init` jobs again
store = jobs.connect!

store\set 'test', 'hello world'
print store\get 'test'

store\jset 'first-job', 'shell', 'echo hello', '5000'
print store\hget 'jobs', 'first-job'