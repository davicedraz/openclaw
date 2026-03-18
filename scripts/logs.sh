#!/bin/sh
set -eu

project_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"

if [ "$#" -eq 0 ]; then
  set -- --follow
fi

exec "$project_root/scripts/compose.sh" run --rm openclaw-cli logs "$@"
