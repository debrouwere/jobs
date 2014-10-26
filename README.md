# Jobs

Jobs is a full-featured scheduler.

Features: 

* **pick your interface**: control jobs from the command-line, through Redis, using client libraries or (soon) via crontab-esque job boards
* **decaying intervals**: run jobs less often or more often as time passes
* **durations**: specify start and stop times for your job or remove a job after a set amount of runs
* **distributed**: run jobs locally, or put job runners on many machines
* **custom runners**: pass on the job payload to any job runner, including your own
* **built for lots of jobs**: manage millions of jobs from a single machine

Use Jobs when the spartan feature set of cron isn't cutting it anymore, but you don't want to commit to a juggernaut like [Chronos](https://github.com/airbnb/chronos), [Luigi](https://github.com/spotify/luigi) or vendor-specific tools like [AWS Data Pipeline](http://aws.amazon.com/datapipeline/) either. 

Jobs runs inside of [Redis](http://redis.io/). At the core of Jobs is a series of custom Redis commands to create, schedule and queue jobs. While it is possible to interact with jobs entirely through Redis, Jobs also includes a command-line interface and a Lua client library. (It's easy to create your own client libraries for other languages, see below.)

## Interacting with Jobs

### Redis

* using evalsha
* by adding custom commands to your redis client library, using the `commands` hash. See below (writing your own client library) for more details

Works well, it's just a bit verbose.

### client libraries

* lua

## Distribute the workload

* basics: open redis port on the machine where your scheduler lives; tell runners where they can get jobs
* better: use our cloudformation/fleet templates

## Runners

* shell

### Write your own runner

* using the wrapper, or, 
* direct interaction with jobs/redis

## Writing your own client library

* low-level
* high-level

## Features under consideration

* **acks, timeouts and retries**: require finished jobs to call back and report success or failure, retry if necessary
* **job boards**: manage jobs in a specification file (similar to crontabs)
* **defaults**: run many jobs with mostly the same options)
* **dependencies**: run a job after one or more other jobs complete)
* **advanced logging**: send logs to cloudwatch
* **job queue**: submit one-off jobs