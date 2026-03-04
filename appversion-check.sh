#!/bin/sh
#
# Health check: verifies the running Prometheus version matches the latest
# GitHub release. Calls /usr/bin/container-version for the running version
# and /usr/bin/container-latest for the latest release tag.
# Returns 0 if versions match, non-zero otherwise.

CURRENT_VERSION=$(/usr/bin/container-version | tr -d '[:space:]')
if [ -z "$CURRENT_VERSION" ]; then
  echo "appversion-check: failed to get running Prometheus version"
  exit 1
fi

LATEST_VERSION=$(/usr/bin/container-latest)
if [ -z "$LATEST_VERSION" ]; then
  echo "appversion-check: failed to get latest Prometheus release version"
  exit 1
fi

echo "Current version: $CURRENT_VERSION"
echo "Latest version:  $LATEST_VERSION"

case "$CURRENT_VERSION" in
  "${LATEST_VERSION}"*)
    echo "appversion-check: version check passed"
    exit 0
    ;;
  *)
    echo "appversion-check: version mismatch — $CURRENT_VERSION does not start with $LATEST_VERSION"
    exit 1
    ;;
esac
