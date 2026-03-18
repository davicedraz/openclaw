#!/bin/sh
set -eu

project_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
env_file="$project_root/.env.local"

if [ -f "$env_file" ]; then
  set -a
  # Mantem o wrapper alinhado com os mesmos valores usados pelo docker compose.
  . "$env_file"
  set +a
fi

compose_cmd="$project_root/scripts/compose.sh"
sandbox_image="${OPENCLAW_SANDBOX_IMAGE:-openclaw-sandbox:bookworm-slim}"
host_port="${OPENCLAW_HOST_PORT:-18789}"
batch_json=$(cat <<EOF
[
  {"path":"agents.defaults.sandbox.mode","value":"all"},
  {"path":"agents.defaults.sandbox.scope","value":"agent"},
  {"path":"agents.defaults.sandbox.workspaceAccess","value":"rw"},
  {"path":"agents.defaults.sandbox.docker.image","value":"$sandbox_image"},
  {"path":"gateway.controlUi.allowedOrigins","value":["http://127.0.0.1:$host_port"]},
  {"path":"tools.deny","value":["exec"]},
  {"path":"tools.elevated.enabled","value":false}
]
EOF
)

"$compose_cmd" up -d openclaw-gateway >/dev/null

exec "$compose_cmd" run --rm --no-deps openclaw-cli \
  config set --batch-json "$batch_json"
