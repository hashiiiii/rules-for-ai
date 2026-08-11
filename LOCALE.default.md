# Locale

Fallback language configuration. Agents read this file only when no local, project, or user locale file exists. Layers never merge.

To override, run the hashiiiii-locale skill and select `user`, `project`, or `local`. Each file contains all five keys.

POSIX-style locale tags, for example `ja_JP`, `en_US`, and `en_GB`.

issues=en_US
pull-requests=en_US
comments=en_US
logs=en_US
test-logs=en_US
