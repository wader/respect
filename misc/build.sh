#!/bin/sh

# exit immediately if some command fail
set -e

# build and run tests
xcodebuild -scheme respect -configuration Debug build test OBJROOT=build SYMROOT=build

# make sure respect is in path and run some sanity usage tests
PATH="$PWD/build/Debug:$PATH" sh RespectTest/usage_tests/run.sh

# show coverage stats or if travis send coverage report to coveralls.io
misc/gcoveralls -target RespectTest -configuration Debug OBJROOT=build SYMROOT=build

