cjson = require 'cjson'
yaml = require 'yaml'
argparse = require 'argparse'
jobs = require 'client/init'
utils = require 'utils/init'

parser = argparse!

with parser
    \name 'job'
    \description utils.dedent [[
        Jobs is a next-generation cron.
    ]]

show     = parser\command('show')\description('show job details')
dump     = parser\command('dump')\description('dump a representation of the entire job board')
remove   = parser\command('remove')\description('remove a job')
create   = parser\command('create')\description('create a job but do not update if it already exists')
put      = parser\command('put')\description('create or update a job')
respond  = parser\command('respond')\description('listen to tasks of a specific type')
init     = parser\command('init')\description('initialize redis with jobs extensions (administrative)')
tick     = parser\command('tick')\description('put jobs that need to run on the queue (administrative)')
-- register = parser\command 'register'
-- board    = parser\command 'board'
-- pop      = parser\command 'pop'
-- next     = parser\command 'next'
-- count    = parser\command 'count'

for command in *{show, dump, remove, create, put, respond, init, tick}
    with command
        \option('-H', '--host')\description('the ip address to Redis')
        \option('-P', '--port')\description('the port to Redis')
        \flag('-S', '--stdin')\description('accept configuration over standard input')

for command in *{show, dump}
    with command
        \option('-f', '--format')\description('the format to output to (yaml, json)')\default('yaml')

for command in *{show, remove}
    with command
        \argument('id')

for command in *{create, put}
    with command
        \argument('id')\description('A job identifier; can be any string.')
        \argument('runner')\description('Which job runner to use, e.g. shell.')
        -- we can also accept a payload over stdin
        \argument('payload')\description('What to pass to the runner.')

        -- unlike cron, these are all intervals, so e.g. a month is not 28, 30 
        -- or 31 days depending on the month, but an interval of 30.4375 days
        \option('-s', '--seconds')\description('Run the job every <seconds> seconds.')
        \option('-m', '--minutes')\description('Run the job every <minutes> minutes.')
        \option('-h', '--hours')\description('Run the job every <hours> hours.')
        \option('-d', '--days')\description('Run the job every <days> days.')
        \option('-w', '--weeks')\description('Run the job every <weeks> weeks.')
        \option('-M', '--months')\description('Run the job every <months> months.')
        \option('-q', '--quarters')\description('Run the job every <quarters> quarters.')
        \option('-y', '--years')\description('Run the job every <years> years.')

        \option('-l', '--lambda')\description('Grow or shrink the interval over time.')
        -- step will use whichever unit is set in --seconds, --minutes etc.
        \option('-x', '--step')\description('After what interval to apply lambda.')

        \option('-f', '--from')\description('Run the job starting at <from> timestamp.')
        \option('-u', '--until')\description('Remove the job after <until> timestamp.')

        -- duration will use whichever unit is set in --seconds, --minutes etc.
        \option('-D', '--duration')\description('Remove the job after <duration> seconds.')
        -- repeat x times (we will calculate stop based on this)
        \option('-r', '--repeat')\description('Remove the job after <repeat> runs.')

with tick
    \option('-t', '--trim', 'Retain at most <n> queued jobs before ticking, to avoid jobs piling up.')

with respond
    \argument('type')\description('What type of job to respond to.')
    \argument('executable')\description('The responding executable.')


execute = (host, port, arguments) ->
    if arguments.init or arguments.tick
        commands = jobs.initialize host, port
        print 'Loading Jobs commands into Redis.\n'
        print 'Loaded:\n'
        for name, sha in pairs commands
            print "  #{name}    \t(#{sha})"
        print ''

    board = jobs.Board 'jobs', host, port

    if arguments.create or arguments.put
        update = if arguments.create then false else true
        options = {:update}

        board\put arguments.id, 
            arguments.runner, arguments.payload, arguments, options

    else if arguments.show
        meta = board\show arguments.id
        switch arguments.format
            when 'json'
                print meta
            when 'yaml'
                meta = cjson.decode meta
                print yaml.dump meta
            else
                error 'format should be one of: yaml, json'

    else if arguments.dump
        dump = board\dump!

        switch arguments.format
            when 'json'
                print cjson.encode dump
            when 'yaml'
                print yaml.dump dump
            else
                error 'format should be one of: yaml, json'

    else if arguments.remove
        board\remove arguments.id

    else if arguments.respond
        print "Responding to #{arguments.type} jobs."
        board\respond arguments.type, arguments.executable

    else if arguments.tick
        print 'Starting the job clock.'
        trim = arguments.trim or (os.getenv 'JOBS_QUEUE_TRIM')
        heartbeat = (meta) ->
            print "[#{meta.timestamp}]
            Queued #{meta.queued} jobs onto #{#meta.queues} queues.
            Trimmed #{meta.trimmed} jobs from the queue."
        utils.forever board\tick, {:trim, :heartbeat}

    else if arguments.register
        error 'not implemented yet'

    else if arguments.board
        error 'not implemented yet'

    else if arguments.pop
        error 'not implemented yet'

    else if arguments.next
        error 'not implemented yet'


arguments = parser\parse!

host = arguments.host or (os.getenv 'JOBS_REDIS_HOST') or '127.0.0.1'
port = arguments.port or (os.getenv 'JOBS_REDIS_PORT') or '6379'

-- accept arguments over standard input
-- (these take precedence over command-line flags)
-- 
-- TODO: possibly, it's better to read line per line
-- and execute the command once per line?
if arguments.stdin
    for input in io.lines!
        options = utils.defaults arguments, (cjson.decode input)
        execute board, options
else
    execute host, port, arguments
