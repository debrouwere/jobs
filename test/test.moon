cjson = require 'cjson'
redis = require 'redis'
connect = require 'client/connect'
initialize = require 'init'
--jobs = require 'src/jobs'

-- TODO: for better testing, to a proper setup/teardown:
-- flushdb + init

describe 'low-level interface', ->
    local store

    setup ->
        store = connect!
        store\flushdb!
        initialize!
        store = connect!

    teardown ->
        store = nil

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

    pending 'can get a job'

    pending 'can calculate when next a job should run'

    pending 'can remove a job'

    pending 'can schedule a job'

    pending 'can schedule a job after start'

    pending 'can unschedule a job beyond stop'

    pending 'can stretch or shrink the job interval'

    pending 'can put scheduled jobs that should run on the queue'

    pending 'can pop a job of the specified type from the queue'


describe 'high-level interface', ->
    pending 'can add a job'    

    pending 'can pop a job of the specified type from the queue'

    pending 'can convert human-readable intervals to seconds'
