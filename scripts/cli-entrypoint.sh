#!/bin/sh
set -eu

. /project/scripts/_load-runtime-secrets.sh

if [ "$#" -eq 0 ]; then
  set -- --help
fi

exec node dist/index.js "$@"
