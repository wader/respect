#!/bin/sh

# exit immediately if some command fails
set -e

# build and run tests
xcodebuild -target respect -configuration Debug OBJROOT=build SYMROOT=build
xcodebuild -target RespectTest -configuration Debug OBJROOT=build SYMROOT=build TEST_AFTER_BUILD=YES

# make sure respect is in path and run some sanity usage tests
PATH="$PWD/build/Debug:$PATH" sh RespectTest/usage_tests/run.sh

# send coverage report to coveralls.io
misc/gcoveralls RespectTest build


