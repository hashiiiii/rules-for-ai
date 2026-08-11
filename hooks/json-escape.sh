#!/bin/sh
# This JSON string escaper supports the Cursor hook wrappers.
#
# It reads text from stdin. It writes the text as JSON string content to stdout.
# The output does not include the surrounding quotes.
# sed doubles backslashes and escapes double quotes.
# awk joins lines with a literal \n.
# The input is machine-written hook text, so it has no other control characters.
# The script does not depend on jq or python.
set -u

sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' \
    | awk 'BEGIN { ORS = "" } NR > 1 { print "\\n" } { print }'
