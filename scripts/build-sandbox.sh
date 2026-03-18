#!/bin/sh
set -eu

project_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"

cd "$project_root/vendor/openclaw"
exec ./scripts/sandbox-setup.sh "$@"
