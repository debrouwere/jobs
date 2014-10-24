all: build

install:

build:
	cd src && moonc -t ../lib .

watch:
	cd src && moonc -t ../lib -w .