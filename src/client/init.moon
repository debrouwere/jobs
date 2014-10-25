-- Jobs reference high-level client library

connect = require 'src/client/connect'
timing = require 'src/utils/timing'


class Queue
    new: (name, board) =>
        @board = board
        @name = name
        @key = @board.keys.queue + ":" + name

    pop: (format='plain') =>
        payload = redis\jpop @key

        switch format
            when 'json'
                cjson.decode payload
            else
                payload


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

    put: (id, runner, payload, schedule, options) =>
        nx = options.update == false
        set = if nx then @client\jsetnx else @client\jset

        interval = timing.seconds schedule

        -- TODO: ideally also support `duration`
        -- and `repeat` shortcuts for start/stop
        if schedule.repeat
            error 'not implemented yet'
        if schedule.duration
            error 'not implemented yet'

        set 3, @keys.board, @keys.schedule, @keys.registry, 
            id, runner, payload, 
            interval, 
            schedule.start, schedule.stop, 
            schedule.lambda, schedule.step

    -- creates but never updates existing jobs
    create: (...) =>
        @put ..., {update: false}

    -- TODO: put a one-off job on the schedule
    -- (no schedule, just act as a job queue)
    schedule: (id, runner, payload) =>
        error 'not implemented yet'

    show: (id) =>
        @client\jget 1, @keys.board, id

    remove: (id) =>
        @client\jdel 2, @keys.board, @keys.schedule, id

    register: (runner, command) =>
        @client\jregister 1, @keys.registry, runner, command

return {
    redis: {:connect}, 
    Board: Board
}