#!/bin/sh
# Shared locale resolver for the session-start hooks.
#
# Usage: resolve-locale.sh [candidate-file ...]
#
# Prints the five locale keys (issues, pull-requests, comments, logs,
# test-logs) from the first candidate file that exists; layers never
# merge. When no candidate exists, prints the inline en_US default so
# a resolved block is never empty (Cursor project/local installs carry
# no bundled LOCALE.default.md).
#
# LOCALE files are machine-written by the hashiiiii-locale skill:
# strict key=value lines, always all five keys, LF endings. The
# resolver trusts that format.
set -u

for f in "$@"; do
    if [ -f "$f" ]; then
        grep -E '^(issues|pull-requests|comments|logs|test-logs)=' "$f"
        exit 0
    fi
done

printf 'issues=en_US\npull-requests=en_US\ncomments=en_US\nlogs=en_US\ntest-logs=en_US\n'
exit 0
