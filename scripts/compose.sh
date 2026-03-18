#!/bin/sh
set -eu

project_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"

exec docker compose \
  --env-file "$project_root/.env.local" \
  -f "$project_root/compose.yaml" \
  "$@"
