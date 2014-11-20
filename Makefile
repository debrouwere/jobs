all: build

install:

build:
	./utils/inline src/redis
	cd src && moonc -t ../lib .

watch:
	cd src && moonc -t ../lib -w .

.PHONY: test
test: build
	busted test/test.moon

test.runners: build
	# can be run with `make test.runners`
	./bin/jobs init
	./bin/jobs put ticker log "hello world" --seconds 5
	./bin/jobs tick
	# run this in a separate shell
	./bin/jobs respond log ./bin/jobs-log-runner
