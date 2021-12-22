#!/bin/sh

readonly __DIR__=`cd $(dirname -- "${0}"); pwd -P`

if [ `find "${__DIR__}/deps" -d 0 -type d -empty | wc -l` -eq 1 ]; then
    MIX_ENV=test mix deps.get
    # TODO: it seems that `mix compile` doesn't compile (CMake?) NIF (expassword_bcrypt or expassword_argon2) but an "explicit" `mix deps.compile` does
    MIX_ENV=test mix deps.compile
fi
mix test
