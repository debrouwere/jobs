all: lib

build: lib

# Travis emulates a C build process, which 
# requires a `make install` step to be present
# 
# To install the binary locally, use
# `luarocks make rockspec/jobs-scm-1.rockspec`
install:

lib: $(wildcard src/*) $(wildcard src/*/*)
	rm -r lib
	./utils/inline src/redis
	cd src && moonc -t ../lib .

image: build
	docker build -t debrouwere/jobs .

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
