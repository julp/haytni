#!/usr/bin/env bash

#readonly __DIR__=`cd $(dirname -- "${0}"); pwd -P`
declare -r __DIR__=$(dirname $(readlink -f "${BASH_SOURCE}"))

pushd "${__DIR__}" > /dev/null
mix gettext.extract
(
    echo '# <extracted from priv>'
    echo ''
    #grep --color=never -norE 'dgettext\("haytni",\s*"[^"]*"(,\s*[[:alpha:]][[:alnum:]_]+:\s*[^,]+)*\)' priv/ | sort -u | gsed -E -e 's/(.+:[[:digit:]]+):dgettext\("haytni",[[:space:]]*/#, elixir-format\n#: \1\nmsgid /' -e 's/(,[[:space:]]*[[:alpha:]][[:alnum:]_]+:[[:space:]]*[^,]+)*\)$/\nmsgstr ""\n/'
    grep --color=never -horE 'dgettext\("haytni",\s*"[^"]*"(,\s*[[:alpha:]][[:alnum:]_]+:\s*[^,]+)*\)' priv/ | sort -u | gsed -E -e 's/^dgettext\("haytni",[[:space:]]*/#, elixir-format\nmsgid /' -e 's/(,[[:space:]]*[[:alpha:]][[:alnum:]_]+:[[:space:]]*[^,]+)*\)$/\nmsgstr ""\n/'
    echo '# </extracted from priv>'
) >> priv/gettext/haytni.pot
for locale in `find priv/gettext/ -type d -depth 1 -exec basename {} \;`; do
    mix gettext.merge priv/gettext --locale "${locale}"
done
popd > /dev/null
