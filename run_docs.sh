#!/bin/sh

readonly __DIR__=`cd $(dirname -- "${0}"); pwd -P`

if [ `find "${__DIR__}/deps" -d 0 -type d -empty | wc -l` -eq 1 ]; then
    mix deps.get
fi
mix docs
