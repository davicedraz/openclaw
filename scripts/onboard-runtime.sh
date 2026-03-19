#!/bin/sh
set -eu

project_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
secret_file="$project_root/secrets/openai_api_key.txt"

case "${1:-}" in
  -h|--help)
    exec "$project_root/scripts/compose.sh" run --rm openclaw-cli onboard "$@"
    ;;
esac

secret_value="$(tr -d '\r\n[:space:]' < "$secret_file" 2>/dev/null || true)"

if [ -z "$secret_value" ]; then
  echo "Preencha $secret_file com a sua OpenAI Project API key antes do onboarding." >&2
  exit 1
fi

exec "$project_root/scripts/compose.sh" run --rm openclaw-cli onboard "$@"
