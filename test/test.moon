cjson = require 'cjson'
redis = require 'redis'
connect = require 'client/connect'
initialize = require 'init'
--jobs = require 'src/jobs'

describe 'low-level interface', ->
    local store

    refresh = ->
        store = connect!
        store\flushdb!
        store\script 'flush'
        initialize!

    before_each refresh
    teardown refresh

    it 'has a low-level redis interface', ->
        expected = 'hello world'
        store\set 'test', expected
        returned = store\get 'test'
        assert.are.equal returned, expected

    it 'can add a job', ->
        expected =
            payload: 'echo hello'
            interval: 5

        status = store\jset 3, 'jobs', 'jobs:schedule', 'jobs:runners', 
            os.time(), 
            'first-job', 'shell', expected.payload, expected.interval

        returned = cjson.decode store\hget 'jobs', 'first-job'

        assert.are.equal expected.payload, returned.payload

    it 'can add but not replace a job', ->
        expected =
            payload: 'echo hello'
            interval: 5
        update =
            payload: 'echo goodbye'
            interval: 2

        status1 = store\jsetnx 3, 'jobs', 'jobs:schedule', 'jobs:runners', 
            os.time(), 
            'second-job', 'shell', expected.payload, expected.interval
        status2 = store\jsetnx 3, 'jobs', 'jobs:schedule', 'jobs:runners', 
            os.time(), 
            'second-job', 'shell', update.payload, update.interval

        returned = cjson.decode store\hget 'jobs', 'second-job'
        assert.are.equal expected.payload, returned.payload

    it 'can initialize a job', ->
        interval = 5
        now = 1000

        next_run = store\jset 3, 'jobs', 'jobs:schedule', 'jobs:runners', 
            now, 'third-job', 'shell', -1, interval

        assert.are.equal next_run, now

    it 'can get a job', ->
        store\hset 'jobs', 'raw-job', cjson.encode {message: 'hello world'}
        a = store\jget 1, 'jobs', 'raw-job'
        b = store\hget 'jobs', 'raw-job'

        assert.are.equal a, b

    it 'can calculate when next a job should run', ->
        board = 'jobs'
        schedule = 'jobs:schedules'
        job = 'test'

        store\hset board, job, cjson.encode {interval: 5}
        store\zadd schedule, 0, job
        
        first  = store\jnext 2, board, schedule, 0, job
        second = store\jnext 2, board, schedule, 4, job
        third = store\jnext 2, board, schedule, 5, job

        assert.equals first, 5
        assert.equals second, 5
        assert.equals third, 10

    it 'can stretch or shrink the job interval', ->
        board = 'jobs'
        schedule = 'jobs:schedules'
        job = 'test'

        store\hset board, job, cjson.encode {
            start: 0, 
            interval: 5, 
            step: 10, 
            lambda: 2, 
            }

        first  = store\jnext 2, board, schedule, 0, job
        first_ = store\jnext 2, board, schedule, 0, job
        second = store\jnext 2, board, schedule, 5, job
        third  = store\jnext 2, board, schedule, 10, job
        third_ = store\jnext 2, board, schedule, 15, job
        fourth = store\jnext 2, board, schedule, 20, job

        -- there's no job in the schedule yet, so 
        -- our first scheduled run will equal `start`
        assert.equals first, 0
        assert.equals first_, 5
        assert.equals second, 10
        assert.equals third, 20
        assert.equals third_, 20
        assert.equals fourth, 40

    pending 'can remove a job', ->
        

    pending 'can schedule a job'

    pending 'can schedule a job after start'

    pending 'can unschedule a job beyond stop'



    pending 'can put scheduled jobs that should run on the queue'

    pending 'can pop a job of the specified type from the queue'


describe 'high-level interface', ->
    pending 'can add a job'    

    pending 'can pop a job of the specified type from the queue'

    pending 'can convert human-readable intervals to seconds'
