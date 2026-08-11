#!/bin/sh
# This locale resolver supports the session-start hooks.
#
# Usage: resolve-locale.sh [candidate-file ...]
#
# It prints five locale keys from the first existing candidate file.
# The keys are issues, pull-requests, comments, logs, and test-logs.
# The locale layers do not merge.
# If no candidate exists, it prints inline en_US values for all keys.
#
# The hashiiiii-locale skill writes LOCALE files.
# These files contain all five keys as strict key=value lines with LF endings.
# The resolver trusts this format.
set -u

for f in "$@"; do
    if [ -f "$f" ]; then
        grep -E '^(issues|pull-requests|comments|logs|test-logs)=' "$f"
        exit 0
    fi
done

printf 'issues=en_US\npull-requests=en_US\ncomments=en_US\nlogs=en_US\ntest-logs=en_US\n'
exit 0
