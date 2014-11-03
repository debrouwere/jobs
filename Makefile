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

test.runners:
	./bin/jobs init
	./bin/jobs put ticker console "hello world" --seconds 5
	./bin/jobs tick
	./bin/jobs respond console ./bin/jobs-console-runner
