-- Jobs reference high-level client library

connect = require 'connect'
timing = require 'timing'


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
    new: (name, ...) =>
        @name = name
        @key = name
        @keys =
            board: @key
            schedule: @key + ":schedule"
            queue: @key + ":queue"
            registry: @key + ":runners"
        @client = connect ...

    put: (id, runner, payload, schedule, options) =>
        if options.update == false
            op = @client\jsetnx
        else
            op = @client\jset

        interval = timing.seconds schedule

        -- TODO: ideally also support `duration`
        -- and `repeat` shortcuts for start/stop
        if schedule.repeat
            error 'not implemented yet'
        if schedule.duration
            error 'not implemented yet'

        op @keys.board, @keys.schedule, @keys.registry, 
            id, runner, payload, 
            interval, 
            schedule.start, schedule.stop, 
            schedule.lambda, schedule.step

    -- creates but never updates existing jobs
    create: (...) =>
        @put ..., {update: false}

    show: (id) =>
        @client\jget @keys.board, id

    delete: (id) =>
        @client\jdel @keys.board, @keys.schedule, id

    register: (runner, command) =>
        @client\jregister @keys.registry, runner, command


return {
    redis: {:connect}, 
    Board: Board
}