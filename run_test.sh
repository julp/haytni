#!/bin/sh

readonly __DIR__=`cd $(dirname -- "${0}"); pwd -P`

readonly PORT="5433"
readonly APP_USER="haytni"
readonly SUPER_USER="julp"
readonly DATABASE="${APP_USER}_test"

if [ `find "${__DIR__}/deps" -d 0 -type d -empty | wc -l` -eq 1 ]; then
    MIX_ENV=test mix deps.get
fi

psql -p "${PORT}" -d "${DATABASE}" -c "SELECT 1" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    if [ "${APP_USER}" != "${SUPER_USER}" ]; then
        createuser -p "${PORT}" "${APP_USER}"
    fi
    createdb -p "${PORT}" -O "${APP_USER}" "${DATABASE}"
    psql -p "${PORT}" -c 'CREATE EXTENSION citext;' -d "${DATABASE}"
fi

mix test "${@}"
