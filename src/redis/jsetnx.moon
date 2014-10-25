-- JSETNX board registry id runner payload interval start stop lambda step
-- e.g. jobs jobs:runners myjob shell 'echo hey' 5000
--
-- keys: board, registry
--
-- create a new job, but don't update the job it already exists


{board, registry} = KEYS
{id} = ARGV
options = [option for option in *ARGV[2,]]

if redis.call 'hexists', board, id
    0
else
    jset = redis.call 'hget', 'commands', 'jset'
    redis.call 'evalsha', jset, 2, board, registry, id, (unpack options)
