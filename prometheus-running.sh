#!/bin/sh
#
# Health check: verifies Prometheus is responding on port 9090.
# Uses curl with a 5-second timeout to probe the HTTP endpoint.
# Returns 0 if Prometheus responds, non-zero otherwise.

if curl -sf --max-time 5 http://localhost:9090/-/healthy > /dev/null 2>&1; then
  echo "prometheus-running: Prometheus health endpoint is responding"
  exit 0
fi

echo "prometheus-running: Prometheus is not responding on port 9090"
exit 1
