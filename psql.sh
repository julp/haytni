#!/bin/sh

cat > /dev/null <<EOM
su -l postgres -c /bin/sh <<EOF
createuser -PE haytni
createdb -O haytni haytni_test
psql -c 'CREATE EXTENSION citext' -d haytni_test
EOF
EOM

readonly PGPASS="${HOME}/.pgpass"
readonly PATTERN='*:5432:haytni_test:haytni:haytni'
if [ ! -f "${PGPASS}" ] || ! grep -qF "${PATTERN}" "${PGPASS}"; then
	oldumask=`umask`
	umask 0177
	echo "${PATTERN}" >> "${PGPASS}"
	umask $oldumask
fi
psql -d haytni_test -U haytni
