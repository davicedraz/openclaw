#!/bin/sh
set -eu

project_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
env_file="$project_root/.env.local"

if [ -f "$env_file" ]; then
  set -a
  # Carrega variaveis nao sensiveis para que a logica do wrapper use os mesmos valores do Compose.
  . "$env_file"
  set +a
fi

compose_files="-f $project_root/compose.yaml"

if [ "${OPENCLAW_SANDBOX_ENABLE:-0}" = "1" ]; then
  socket_path="${OPENCLAW_DOCKER_SOCKET_PATH:-/var/run/docker.sock}"

  if [ ! -S "$socket_path" ]; then
    echo "Sandbox habilitado, mas o socket Docker nao existe em $socket_path." >&2
    echo "Revise OPENCLAW_DOCKER_SOCKET_PATH ou inicie o Docker antes de rodar os wrappers." >&2
    exit 1
  fi

  docker_gid="$(stat -c '%g' "$socket_path" 2>/dev/null || stat -f '%g' "$socket_path" 2>/dev/null || true)"

  if [ -z "$docker_gid" ]; then
    echo "Nao foi possivel detectar o GID do socket Docker em $socket_path." >&2
    exit 1
  fi

  export OPENCLAW_DOCKER_SOCKET_PATH="$socket_path"
  export OPENCLAW_DOCKER_GID="$docker_gid"
  compose_files="$compose_files -f $project_root/compose.sandbox.yaml"
fi

exec docker compose \
  --env-file "$env_file" \
  $compose_files \
  "$@"
