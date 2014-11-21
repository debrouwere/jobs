cjson = require 'cjson'
redis = require 'redis'
jobs = require 'client/init'
initialize = require 'initialize'


-- The unit tests for the low-level interface try to tread
-- a fine line between being decoupled enough to actually
-- test "units" (one faulty component shouldn't break
-- all tests) while at the same time not writing tests 
-- that are overly dependent on implementation details, 
-- which might change.
-- 
-- I should probably add mocks and stubs at some point, 
-- but can't be bothered at this point.


describe 'low-level interface', ->
    local store

    refresh = ->
        store = jobs.redis.connect!
        store\flushdb!
        store\script 'flush'
        initialize!

    before_each refresh
    teardown refresh

    board = 'jobs'
    schedule = 'queue'
    registry = 'jobs:runners'
    runner = 'shell'
    queue = 'jobs:queue:' .. runner
    job = 'first-job'

    it 'has a low-level redis interface', ->
        expected = 'hello world'
        store\set 'test', expected
        returned = store\get 'test'
        assert.are.equal returned, expected

    it 'can add a job', ->
        expected =
            payload: 'echo hello'
            interval: 5

        status = store\jset 3, board, schedule, registry, 
            os.time(), 
            job, runner, expected.payload, expected.interval

        returned = cjson.decode store\hget 'jobs', 'first-job'

        assert.are.equal expected.payload, returned.payload

    it 'can add but not replace a job', ->
        expected =
            payload: 'echo hello'
            interval: 5
        update =
            payload: 'echo goodbye'
            interval: 2

        status1 = store\jsetnx 3, board, schedule, registry, 
            os.time(), 
            'second-job', 'shell', expected.payload, expected.interval
        status2 = store\jsetnx 3, board, schedule, registry, 
            os.time(), 
            'second-job', 'shell', update.payload, update.interval

        returned = cjson.decode store\hget 'jobs', 'second-job'
        assert.are.equal expected.payload, returned.payload

    it 'can initialize a job', ->
        interval = 5
        now = 1000

        next_run = store\jset 3, board, schedule, registry, 
            now, 'third-job', 'shell', -1, interval

        assert.are.equal next_run, now

    it 'can get a job', ->
        store\hset 'jobs', 'raw-job', cjson.encode {message: 'hello world'}
        a = store\jget 1, 'jobs', 'raw-job'
        b = store\hget 'jobs', 'raw-job'

        assert.are.equal a, b

    it 'can schedule a job', ->
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

    it 'can remove a job', ->
        store\hset board, 'test', 'test'
        store\jdel 1, board, 'test'
        status = store\jget 1, 'jobs', 'test'

        assert.falsy status

    it 'can schedule a job after start', ->
        now = 100
        expected =
            start: 500
            payload: 'echo hello'
            interval: 5

        status = store\jset 3, 'jobs', 'jobs:schedule', 'jobs:runners', 
            now, 
            'first-job', 'shell', expected.payload, 
            expected.interval, expected.start

        next_run = store\zscore 'jobs:schedule', 'first-job'

        assert.equals (tonumber next_run), expected.start

    it 'can unschedule a job beyond stop', ->
        now = 500
        expected =
            stop: 600
            payload: 'echo hello'
            interval: 5

        store\jset 3, board, schedule, registry, 
            now, 
            job,  runner, expected.payload, 
            expected.interval, -1, expected.stop

        a = store\zscore schedule, job
        store\jnext 2, board, schedule, expected.stop, job
        b = store\zscore schedule, job

        assert.true (tonumber a) <= now
        assert.falsy b

    it 'can put scheduled jobs that should run on the queue', ->
        earlier = 50
        now = 100

        interval = 5

        store\jset 3, board, schedule, registry, 
            now, job, runner, -1, interval

        next_run = store\zscore schedule, job
        assert.true (tonumber next_run) <= now

        pushed = store\jtick 3, board, schedule, queue, earlier
        task = store\rpop queue
        assert.equals (tonumber pushed), 0
        assert.falsy task
        pushed = store\jtick 3, board, schedule, queue, now
        task = store\rpop queue
        assert.equals (tonumber pushed), 1
        meta = cjson.decode task
        assert.truthy task
        assert.equals meta.interval, interval

        -- a tick should also properly update the 
        -- schedule for popped jobs
        next_run = store\zscore schedule, job
        assert.true (tonumber next_run) >= now

    it 'can push jobs into the proper queues', ->
        a = 'job-a'
        a_queue = 'jobs:queue:one'
        b = 'job-b'
        b_queue = 'jobs:queue:two'

        store\hset board, a, cjson.encode {
            id: a, 
            stop: 0, 
            runner: 'one'
        }
        store\zadd schedule, 0, a
        
        store\hset board, b, cjson.encode {
            id: b, 
            stop: 0, 
            runner: 'two'
        }
        store\zadd schedule, 0, b

        -- can't pop something before it's scheduled
        assert.falsy store\jpop 1, a_queue
        store\jtick 3, board, schedule, b_queue, 1000
        raw = store\jpop 1, b_queue
        task = cjson.decode raw

        -- popping should return the job metadata
        assert.equals task.id, b

        -- can't pop a job twice
        assert.falsy store\jpop 1, b_queue


describe 'high-level interface', ->
    timing = require 'utils/timing'

    local store
    local board

    refresh = ->
        store = jobs.redis.connect!
        store\flushdb!
        store\script 'flush'
        initialize!
        board = jobs.Board!

    before_each refresh
    teardown refresh

    name = 'first-job'
    runner = 'shell'
    payload = 'echo "hello world"'
    params = 
        seconds: 5

    it 'can convert responses to the proper types', ->
        next_run = board\put name, runner, payload, params
        assert.equals (type next_run), 'number'

    it 'can parse job metadata or leave it as a string', ->
        board\put name, runner, payload, params
        plain = board\show name
        t = board\show name, 'json'

        assert.equals (type plain), 'string'
        assert.equals (type t), 'table'

    it 'can add a job', ->
        board\put name, runner, payload, params
        raw = store\hget 'jobs', name
        meta = cjson.decode raw
        assert.equals meta.interval, 5

    it 'can pop a job of the specified type from the queue', ->
        board\put 'first-shell-job', 'shell', payload, params        
        board\put 'first-console-job', 'console', payload, params
        
        -- how many queues did the tick affect?
        queues = board\tick!
        assert.equals queues, 2
        task = board\queue('console')\pop 'json'
        assert.equals task.id, 'first-console-job'
        task = board\queue('console')\pop 'json'
        assert.falsy task

    it 'can convert human-readable intervals to seconds', ->
        time = 
            seconds: 3
            minutes: 1
            hours: 2

        assert.equals (timing.seconds time), 7263
