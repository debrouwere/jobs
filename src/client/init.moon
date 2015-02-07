-- Jobs reference high-level client library

cjson = require 'cjson'
initialize = require 'initialize'
connect = require 'client/connect'
utils = require 'utils/init'

parse = (str, format='plain') ->
    if (type str) == 'string'
        switch format
            when 'json'
                str = cjson.decode str
            when 'plain'
                str = str
            else
                error "unsupported format: got #{format}, expected json or plain"

    str


class Queue
    new: (name, board) =>
        @board = board
        @client = @board.client
        @name = name
        @key = @board.keys.queue .. ":" .. name

    pop: (format='plain') =>
        meta = @client\jpop 1, @key
        parse meta, format

    listen: (...) =>
        local format, listener
        arguments = {...}

        switch #arguments
            when 1
                format = 'plain'
                {listener} = arguments
            when 2
                {format, listener} = arguments
            else
                error 'listen takes two arguments: format and listener'

        utils.forever ->
            -- there might be no pending jobs, but if there
            -- is one, pass it to the listener
            popped = @pop format
            if popped
                listener popped


class Board
    new: (name='jobs', ...) =>
        @name = name
        @key = name
        @keys =
            board: @key
            schedule: @key .. ":schedule"
            queue: @key .. ":queue"
            registry: @key .. ":runners"
        @client = connect ...

    put: (id, runner, payload, schedule, options={}) =>
        now = os.time()

        nx = options.update == false
        set = if nx then @client\jsetnx else @client\jset

        interval = utils.timing.seconds schedule

        -- TODO: ideally also support `duration`
        -- and `repeat` shortcuts for start/stop
        if schedule.repeat
            error 'not implemented yet'
        if schedule.duration
            schedule.start = schedule.start or now
            schedule.stop = schedule.start + (tonumber schedule.duration)
        
        next_run = set 3, @keys.board, @keys.schedule, @keys.registry, 
            now, 
            id, runner, payload, 
            interval, 
            schedule.start, schedule.stop, 
            schedule.lambda, schedule.step

        tonumber next_run

    -- creates but never updates existing jobs
    create: (...) =>
        @put ..., {update: false}

    -- TODO: put a one-off job on the schedule
    -- (no schedule, just act as a job queue)
    schedule: (id, runner, payload) =>
        error 'not implemented yet'

    show: (id, format='plain') =>
        meta = @client\jget 1, @keys.board, id
        parse meta, format

    dump: =>
        runners = @client\hgetall @keys.registry
        jobs = @client\hgetall @keys.board
        out = {}
        out.runners = runners
        out.jobs = {}
        for id, serialized_meta in pairs(jobs)
            meta = cjson.decode serialized_meta
            out.jobs[id] = meta
        out

    load: (board) =>
        @client\hmset @keys.registry, board.runners
        jobs = {}
        for id, meta in pairs(board.jobs)
            jobs[id] = cjson.encode meta
        @client\hmset @keys.board, jobs

    count: =>
        queues = [queue.key for queue in *@get_queues!]
        n_keys = 3 + #queues
        counts = @client\jcount n_keys, @keys.board, @keys.schedule, @keys.registry, queues
        cjson.decode counts

    remove: (id) =>
        n_removed = @client\jdel 2, @keys.board, @keys.schedule, id
        tonumber n_removed

    register: (runner, command) =>
        @client\jregister 1, @keys.registry, runner, command

    get_queue: (name) =>
        Queue name, @

    get_queues: =>
        list = {}
        runners = @client\hgetall @keys.registry
        for runner, command in pairs runners
            table.insert list, (@get_queue runner)
        list

    tick: (options={}) =>
        now = options.now or os.time()
        queues = [queue.key for queue in *@get_queues!]
        trimmed = 0

        if options.trim
            trimmed = @trim options.trim, unpack(queues)

        n_queues = #queues
        n_keys = n_queues + 2

        -- Lua quirk: unpack has to be the final argument, 
        -- so we tack on `now` instead of specifying it 
        -- separately during the function call
        table.insert queues, now
        queued = @client\jtick n_keys, @keys.board, @keys.schedule, unpack(queues)

        if options.heartbeat
            options.heartbeat {
                timestamp: now, 
                queues: queues, 
                queued: queued, 
                trimmed: trimmed,                 
            }

        n_queues

    trim: (n=-1, ...) =>
        queues = {...}
        if #queues > 0
            queues = utils.copy queues
        else
            queues = [queue.key for queue in *@get_queues!]

        n_queues = #queues
        table.insert queues, n
        @client\jtrim n_queues, unpack(queues)

    respond: (queue, command) =>
        queue = @get_queue queue

        inline = string.match command, '{payload}'
        stdin = not inline
        if inline
            {payload} = cjson.decode meta
            command = string.gsub command, '{payload}', payload

        queue\listen (meta) ->
            if stdin
                process = io.popen command, 'w'
                process\write meta
                process\close!
            else
                os.execute command


return {
    initialize: initialize, 
    redis: {:connect}, 
    Board: Board, 
    Queue: Queue
}
