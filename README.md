# Jobs

[![Build Status](https://travis-ci.org/debrouwere/jobs.svg?branch=master)](https://travis-ci.org/debrouwere/jobs)

Jobs is a full-featured scheduler. **Warning:** not quite ready for prime time, don't use this.

Features: 

* **pick your interface**: control jobs from the command-line, through Redis, using client libraries or (soon) via crontab-esque job boards
* **decaying intervals**: run jobs less often or more often as time passes
* **durations**: specify start and stop times for your job or remove a job after a set amount of runs
* **distributed**: run jobs locally, or put job runners on many machines
* **custom runners**: pass on the job payload to any job runner, including your own
* **built for lots of jobs**: manage millions of jobs from a single machine

Use Jobs when the spartan feature set of cron isn't cutting it anymore, but you don't want to commit to a juggernaut like [Chronos](https://github.com/airbnb/chronos), [Luigi](https://github.com/spotify/luigi) or vendor-specific tools like [AWS Data Pipeline](http://aws.amazon.com/datapipeline/) either. 

Jobs runs inside of [Redis](http://redis.io/). At the core of Jobs is a series of custom Redis commands to create, schedule and queue jobs. While it is possible to interact with jobs entirely through Redis, Jobs also includes a command-line interface and a Lua client library. (It's easy to create your own client libraries for other languages, see below.)

## Installation

First, install [Lua](http://www.lua.org/), [Luarocks](http://luarocks.org/en/Download) and [Redis](http://redis.io/). Then, install Jobs with Luarocks.

On OS X, with [Homebrew](http://brew.sh/):

```shell
    brew update
    brew install redis lua luarocks
    luarocks install jobs
```

On Linux with APT:

```shell
    apt-get install redis-server lua5.1 liblua5.1-dev luarocks
    luarocks install jobs
```

At this point you'll have a working Jobs installation, but you will still want to daemonize the `jobs tick` command, so jobs are added to the proper job queues when they should run, and – if running a minimal local installation – you'll also want to daemonize the actual job runners. (The ticker and local runners are under development.)

## Working with Jobs

### Interactively

The easiest way to get started with Jobs is through the command-line interface. You can add, view and remove jobs using the command-line. See `jobs --help` for more information.

Another way to work with Jobs is through job boards – Jobs' version of crontabs. (Job boards are under development.)

### Programmatically

Alternatively, you can run `jobs init` which will tell you the sha hashes for each command, so you can run the custom Redis job commands using [evalsha](http://redis.io/commands/evalsha).

While interacting with Jobs through Redis works great, it's also quite verbose. For Lua, there's client library that makes things easier:

```lua
-- high-level client library
-- run a job every three minutes and five seconds, 
-- for an hour
local jobs = require('jobs/client/init')
local now = os.time()
local later = now + 60 * 60
local board = jobs.Board()
board:set('my job', 'console', 'hello world', {
    minutes = 3
    seconds = 5
    stop = later
})

-- low-level client library: make commands 
-- accessible using their name rather than
-- their sha hash, but nothing more
local jobs = require('jobs/client/init')
local client = jobs.redis.connect()
local now = os.time()
local later = now + 60 * 60
client:jset(3, 'jobs', 'jobs:schedule', 'jobs:runners', now, 
    'my job', 'console', 'hello world', 185, -1, later)

-- plain redis
local redis = require('redis')
local jset = client:hget('commands', 'jset')
local now = os.time()
local later = now + 60 * 60
client:evalsha(jset, 3, 'jobs', 'jobs:schedule', 'jobs:runners', now, 
    'my job', 'console', 'hello world', 185, -1, later)
```

Pending better documentation, take a look at `src/redis`. The header to each command describes the function signature and includes an example.

### Creating your own client library

If you'd like to access Jobs from within your code (as opposed to through the command-line or through a job board) you can. Jobs comes with a client library for Lua, described above, but for other languages you'll have to create something similar yourself.

First, you will want a system that turns job commands into their equivalent evalshas. You can get this mapping from the `commands` hash in Redis. Most Redis client libraries have the ability to add custom commands.

Secondly, while Redis commands should always specify all the keys they operate on (which is why in the code above, we keep referring to `jobs`, `jobs:schedule`, and `jobs:runners`), but in a client library you can just hardcode these so the end user doesn't have to specify them over and over again.

Finally, the Redis commands require all arguments to be entered in the right order. In a client library, you might accept a range of options (start and stop time, interval) and then put these in the right order when sending them off to Redis. It's also nice to give users the option to specify times in seconds, minutes, hours and days. Just convert them all to seconds, which is what the `JSET` command expects.

Take a look at the code in `src/client/init` (the high-level client library) and `src/client/connect` to get an idea of what an implementation of a client library could look like. It's around 135 lines of code.

## Distributing the workload

Jobs can run on a single computer and can do most things that cron can. But because Jobs has a message queue at the heart of it, it's also pretty easy to distribute a workload over multiple machines.

In short, you open the Redis port (default: 6379) on the machine where your scheduler lives, and then you point the runners (whether built-in or your own) to the right IP and port so they know from where they can pull jobs.

We're working on cloudformation/fleet templates to simplify deployment.

## Runners

Currently, there's just two runners: 

* **shell** is what you're used to from cron: run commands on a shell
* **console** outputs the job payload to stdout, which is useful for logging and debugging

### Write your own runner

A runner is simply an application that can be run from the command-line and that accepts job metadata over standard input. Use `jobs respond <type> "<command>"` to hook up the runner to your Jobs instance.

Alternatively, just `JPOP` tasks from a job queue (e.g. `jobs:queue:console`.)

## Features under consideration

* **acks, timeouts and retries**: require finished jobs to call back and report success, failure or a status update; retry if necessary (`JACK job-id 0|1|2` – success, failure, status update)
* **job boards**: manage jobs in a specification file (similar to crontabs)
* **defaults**: run many jobs with mostly the same options)
* **dependencies**: run a job after one or more other jobs complete (`JWHEN job-id type payload dependencies...`)
* **job queue**: submit one-off jobs
* **advanced logging**: send logs to cloudwatch
* **dashboard**: an overview of job failures and successes, with the possibility to drill down to individual jobs
