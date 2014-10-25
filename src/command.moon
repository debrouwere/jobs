-- 
-- Keep in mind that I'm stubbing out my ideal CLI
-- here. It doesn't have to be quite this full-featured
-- from the start.
-- 

argparse = require 'argparse'
jobs = require 'jobs.lua'

with parser = argparse!
    \name 'jobs'
    \description 'tk'
    -- create, put, show, delete
    -- register (register a runner)
    -- board (load/update jobs from a job board file)
    -- pop, next (shows next, doesn't change it unless it's in the past)
    -- tick (core feature -- the heartbeat of jobs)
    \argument 'action'

    --
    -- all options and arguments for `put`
    --
    \argument 'runner'
    -- we can also accept a payload over stdin
    \argument 'payload'

    \option '-s', '--seconds'
    \option '-m', '--minutes'
    \option '-h', '--hours'
    \option '-d', '--days'

    \option '-l', '--lambda'
    -- step will use whichever unit is set in --seconds, --minutes etc.
    \option '-x', '--step'

    \option '-n', '--only-if-new'

    \option '-f', '--from'
    \option '-u', '--until'

    -- duration will use whichever unit is set in --seconds, --minutes etc.
    \option '-D', '--duration'
    -- repeat x times (we will calculate stop based on this)
    \option '-r', '--repeat'
