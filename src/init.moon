lfs = require 'lfs'
redis = require 'redis'


return ->
    scriptfiles = {}
    scripts = {}
    commands = {}

    -- find and load command scripts
    source = debug.getinfo(1).source
    here = string.match source, '^@(.+)/.+$'
    commands_directory = "#{here}/../lib/redis"

    for file in lfs.dir commands_directory
        if name = string.match file, '(.+)\.lua$'
            table.insert scriptfiles, name

    for name in *scriptfiles
        file = io.open "#{commands_directory}/#{name}.lua"
        table.insert scripts, file\read '*all'
        file\close!

    -- load command scripts into redis
    -- TODO: make host and port configurable
    store = redis.connect '127.0.0.1', 6379

    evalshas = store\pipeline (pipeline) ->
        for script in *scripts
            pipeline\script 'load', script

    for i, sha in ipairs evalshas
        name = scriptfiles[i]
        commands[name] = sha

    -- refresh the commands table
    store\del 'commands'
    for name, sha in pairs commands
        store\hset 'commands', name, sha

    -- return loaded commands (useful during 
    -- testing and as a sanity check)
    store\hgetall 'commands'
