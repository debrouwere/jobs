all: build

install:

build:
	./utils/weave src/redis
	cd src && moonc -t ../lib .

watch:
	cd src && moonc -t ../lib -w .

.PHONY: test
test: build
	busted test/test.moon