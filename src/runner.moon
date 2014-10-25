-- TODO: do try to see if we can't fork a subprocess with the posix module

-- TODO: properly output to stdout and stderr, so we can keep logs

argparse = require 'argparse'
client = require 'client'

with parser = argparse!
    \name 'runner'
    \description 'tk'
    \option '-t', '--type' -- what queue to pop from

args = parser\parse!

queue = client.queues[runner]
payload = queue.pop 'json'

if string.match command, '{payload}'
    string.gsub command, '{payload}', payload
    os.execute!
else
    -- use stdin
    os.pipe!


-- TODO: once we have support for acking, do that