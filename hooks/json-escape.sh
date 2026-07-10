#!/bin/sh
# JSON string escaper shared by the Cursor hook wrappers.
#
# Reads text on stdin and writes it as the CONTENT of a JSON string on
# stdout (no surrounding quotes): sed doubles backslashes and escapes
# double quotes, awk joins lines with a literal \n. Input is
# machine-written hook text (locale key=value lines, block reasons), so
# other control characters do not occur; there is deliberately no jq or
# python dependency.
set -u

sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' \
    | awk 'BEGIN { ORS = "" } NR > 1 { print "\\n" } { print }'
