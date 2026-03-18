#!/bin/sh
set -eu

project_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"

"$project_root/scripts/compose.sh" up -d openclaw-gateway >/dev/null

exec "$project_root/scripts/compose.sh" run --rm --no-deps openclaw-cli sandbox explain "$@"
