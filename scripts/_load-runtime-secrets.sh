#!/bin/sh
set -eu

load_runtime_secret() {
  env_name="$1"
  secret_file="$2"

  eval "current_value=\${$env_name:-}"

  if [ -n "$current_value" ] || [ ! -f "$secret_file" ]; then
    return
  fi

  secret_value="$(tr -d '\r\n' < "$secret_file")"

  if [ -n "$secret_value" ]; then
    eval "export $env_name=\$secret_value"
  fi
}

load_runtime_secret OPENAI_API_KEY /run/secrets/openai_api_key
load_runtime_secret GEMINI_API_KEY /run/secrets/gemini_api_key
