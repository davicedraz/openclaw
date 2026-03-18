#!/bin/sh
set -eu

secret_file="/run/secrets/openai_api_key"

if [ -f "$secret_file" ] && [ -z "${OPENAI_API_KEY:-}" ]; then
  export OPENAI_API_KEY="$(tr -d '\r\n' < "$secret_file")"
fi
