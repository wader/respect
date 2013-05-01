#!/bin/sh

# exit immediately if some command fails
set -e

# build and run unit tests
xcodebuild -target respect OBJROOT=build SYMROOT=build
xcodebuild -target RespectTest OBJROOT=build TEST_AFTER_BUILD=YES

# send coverage report to coveralls.io
misc/gcoveralls RespectTest build


