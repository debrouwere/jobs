all: build

install:

build:
	./utils/inline src/redis
	cd src && moonc -t ../lib .

stack.cloudformation:
	yaml2json stack/stack.yml --indent 2 > stack/stack.json

stack.docker:
	docker build -t debrouwere/jobs .

.PHONY: stack
stack: build stack.cloudformation stack.docker

watch:
	cd src && moonc -t ../lib -w .

.PHONY: test
test: build
	busted test/test.moon

test.runners: build
	# can be run with `make test.runners`
	./bin/job put ticker log "hello world" --seconds 5
	./bin/job tick
	# run this in a separate shell
	./bin/job respond log ./bin/jobs-log-runner
