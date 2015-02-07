-- JSETNX board schedule registry now id runner payload interval start stop lambda step
-- e.g. jobs jobs:schedule jobs:runners 1414139992 myjob shell 'echo hey' 5000
--
-- keys: board, schedule, registry
--
-- create a new job, but don't update the job it already exists


{board} = KEYS
{now, id} = ARGV

if (redis.call 'hexists', board, id) == 1
    0
else 
    require 'jset'
