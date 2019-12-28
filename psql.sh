#!/bin/sh

readonly PGPASS="${HOME}/.pgpass"
readonly PATTERN='*:5432:haytni_test:haytni:haytni'
if [ ! -f "${PGPASS}" ] || ! grep -qF "${PATTERN}" "${PGPASS}"; then
	echo "${PATTERN}" >> "${PGPASS}"
fi
psql -d haytni_test -U haytni

