# Build native GRAPE-3 CPU interface and its Fortran smoke test.
CC ?= gcc
FC = gfortran
CFLAGS ?= -O2 -std=c11 -Wall -Wextra -Wpedantic
FFLAGS ?= -O2 -Wall -Wextra -fcheck=all
IMAGE ?= grapesph-grape3-cpu:0.1.0

.PHONY: all test clean docker-build docker-run
all: bin/grape3_demo

build/grape3_cpu.o: src/grape3_cpu.c
	mkdir -p build
	$(CC) $(CFLAGS) -c $< -o $@

build/demo.o: src/demo.f90
	mkdir -p build
	$(FC) $(FFLAGS) -c $< -o $@

bin/grape3_demo: build/grape3_cpu.o build/demo.o
	mkdir -p bin
	$(FC) $(FFLAGS) $^ -lm -o $@

test: bin/grape3_demo
	mkdir -p results
	./bin/grape3_demo results/demo.csv

docker-build:
	docker build -t $(IMAGE) .

docker-run:
	mkdir -p results
	docker run --rm --user "$$(id -u):$$(id -g)" -v "$$(pwd)/results:/workspace/results" $(IMAGE) /usr/local/bin/grape3_demo results/demo.csv

clean:
	rm -rf build bin results/demo.csv
