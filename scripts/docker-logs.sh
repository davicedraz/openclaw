#!/bin/sh
set -eu

project_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"

if [ "$#" -eq 0 ]; then
  set -- -f
fi

exec "$project_root/scripts/compose.sh" logs "$@" openclaw-gateway
