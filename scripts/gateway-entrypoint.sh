#!/bin/sh
set -eu

. /project/scripts/_load-runtime-secrets.sh

exec node dist/index.js gateway \
  --allow-unconfigured \
  --bind "${OPENCLAW_GATEWAY_BIND:-lan}" \
  --port "18789"
