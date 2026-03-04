#!/bin/sh
#
# Returns the version of the installed prometheus binary.
# Parses the output of `prometheus --version`.
# Returns non-zero if the version cannot be determined.

VERSION=$(prometheus --version 2>&1 | head -1 | awk '{print $3}' | tr -d '[:space:]')

if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
  echo "Failed to determine Prometheus version" >&2
  exit 1
fi

printf '%s\n' "$VERSION"
