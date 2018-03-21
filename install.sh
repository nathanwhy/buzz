#!/bin/sh
swift package clean
swift test
swift build -c release
cp .build/release/buzz /usr/local/bin/buzz