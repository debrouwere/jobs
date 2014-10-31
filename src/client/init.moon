-- Jobs reference high-level client library

cjson = require 'cjson'
connect = require 'lib/client/connect'
timing = require 'lib/utils/timing'

parse = (str, format) ->
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

    listen: =>
        local format, listener

        switch #args
            when 1
                format = 'plain'
                {listener} = args
            when 2
                {format, listener} = args
            else
                error 'listen takes two arguments: format and listener'

        last = os.time()
        while true
            -- pop at most once a second
            now = os.time()
            if now > last
                last = now
                popped = @pop format
                -- there might be no pending jobs
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
        nx = options.update == false
        set = if nx then @client\jsetnx else @client\jset

        interval = timing.seconds schedule

        -- TODO: ideally also support `duration`
        -- and `repeat` shortcuts for start/stop
        if schedule.repeat
            error 'not implemented yet'
        if schedule.duration
            error 'not implemented yet'

        now = os.time()
        
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

    show: (id, format) =>
        meta = @client\jget 1, @keys.board, id
        parse meta, format

    remove: (id) =>
        n_removed = @client\jdel 2, @keys.board, @keys.schedule, id
        tonumber n_removed

    register: (runner, command) =>
        @client\jregister 1, @keys.registry, runner, command

    queue: (name) =>
        Queue name, @

    tick: (now) =>
        now = now or os.time()
        runners = @client\hgetall @keys.registry
        queues = {}
        for runner, command in pairs runners
            table.insert queues, (@queue runner).key

        n_queues = #queues
        n_keys = n_queues + 2

        -- Lua quirk: unpack has to be the final argument, 
        -- so we tack on `now` instead of specifying it 
        -- separately during the function call
        table.insert queues, now
        @client\jtick n_keys, @keys.board, @keys.schedule, unpack(queues)

        n_queues

    respond: (queue, command) ->
        queue = @queues queue
        queue\listen (meta) ->
            if string.match command, '{payload}'
                command = string.gsub command, '{payload}', payload
                os.execute command
            else
                command = io.popen command, 'w'
                command\write meta


return {
    redis: {:connect}, 
    Board: Board, 
    Queue: Queue
}
