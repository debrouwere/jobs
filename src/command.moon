argparse = require 'argparse'
jobs = require 'lib/client/init'
initialize = require 'lib/init'
utils = require 'lib/utils/init'

parser = argparse!

with parser
    \name 'job'
    \description utils.dedent [[
        Jobs is a next-generation cron.
    ]]

show     = parser\command('show')\description('show job details')
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

for command in *{show, remove}
    with command
        \argument('name')

for command in *{create, put}
    with command
        \argument('name')\description('A job identifier; can be any string.')
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

with respond
    \argument('type')\description('What type of job to respond to.')
    \argument('executable')\description('The responding executable.')

arguments = parser\parse!

board = jobs.Board!

if arguments.init
    commands = initialize!
    print 'Loading Jobs commands into Redis.\n'
    print 'Loaded:\n'
    for name, sha in pairs commands
        print "  #{name}    \t(#{sha})"
    print ''

if arguments.create or arguments.put
    update = if arguments.create then false else true
    options = {:update}

    board\put arguments.name, 
        arguments.runner, arguments.payload, arguments, options

else if arguments.show
    print board\show arguments.name

else if arguments.remove
    board\remove arguments.name

else if arguments.respond
    board\respond arguments.type, arguments.executable

else if arguments.tick
    utils.forever board\tick

else if arguments.register
    error 'not implemented yet'

else if arguments.board
    error 'not implemented yet'

else if arguments.pop
    error 'not implemented yet'

else if arguments.next
    error 'not implemented yet'
