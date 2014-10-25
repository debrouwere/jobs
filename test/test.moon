cjson = require 'cjson'
connect = require 'client/connect'
--jobs = require 'src/jobs'

-- TODO: for better testing, to a proper setup/teardown:
-- flushdb + init

describe 'jobs', ->
    it 'can connect to redis', ->
        store = connect!
        expected = 'hello world'
        store\set 'test', expected
        returned = store\get 'test'
        assert.are.equal returned, expected

    it 'has a low-level redis interface', ->
        store = connect!
        expected =
            payload: 'echo hello'
            interval: 5000

        status = store\jset 3, 'jobs', 'jobs:schedule', 'jobs:runners', 
            'first-job', 'shell', expected.payload, expected.interval
        returned = cjson.decode store\hget 'jobs', 'first-job'

        assert.are.equal expected.payload, returned.payload
