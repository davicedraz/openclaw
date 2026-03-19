#!/bin/sh
set -eu

project_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
env_file="$project_root/.env.local"
compose_cmd="$project_root/scripts/compose.sh"
gemini_secret_file="$project_root/secrets/gemini_api_key.txt"
placeholder_owner="__PREENCHER_OWNER_E164__"
placeholder_group_jid="__PREENCHER_GROUP_JID__"

usage() {
  cat <<'EOF'
Uso: ./scripts/whatsapp-browser-enable.sh

Aplica o baseline conservador do perfil "WhatsApp dedicado + browser"
sem adivinhar numeros/JIDs do operador.
EOF
}

case "${1:-}" in
  "")
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

if [ -f "$env_file" ]; then
  set -a
  # Mantem o wrapper alinhado com os mesmos valores usados pelo docker compose.
  . "$env_file"
  set +a
fi

config_path_exists() {
  "$compose_cmd" run --rm --no-deps openclaw-cli config get "$1" --json >/dev/null 2>&1
}

config_get_json() {
  "$compose_cmd" run --rm --no-deps openclaw-cli config get "$1" --json 2>/dev/null || true
}

contains_text() {
  haystack="$1"
  needle="$2"

  case "$haystack" in
    *"$needle"*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

compact_json() {
  printf '%s' "$1" | tr -d '\n\r\t '
}

refuse_permissive_wildcards() {
  has_error=0
  allow_from_json="$(config_get_json channels.whatsapp.allowFrom)"
  group_allow_from_json="$(config_get_json channels.whatsapp.groupAllowFrom)"
  groups_json="$(config_get_json channels.whatsapp.groups)"

  if [ -n "$allow_from_json" ] && contains_text "$(compact_json "$allow_from_json")" '"*"'; then
    echo 'channels.whatsapp.allowFrom ainda usa wildcard "*".' >&2
    echo "Troque por owners explicitos antes de aplicar este perfil." >&2
    has_error=1
  fi

  if [ -n "$group_allow_from_json" ] && contains_text "$(compact_json "$group_allow_from_json")" '"*"'; then
    echo 'channels.whatsapp.groupAllowFrom ainda usa wildcard "*".' >&2
    echo "Troque por remetentes explicitos antes de aplicar este perfil." >&2
    has_error=1
  fi

  if [ -n "$groups_json" ] && contains_text "$(compact_json "$groups_json")" '"*":'; then
    echo 'channels.whatsapp.groups ainda usa o wildcard groups."*".' >&2
    echo "Troque por JIDs explicitos ou volte ao bloqueio fail-closed antes de aplicar este perfil." >&2
    has_error=1
  fi

  if [ "$has_error" -ne 0 ]; then
    echo "Nenhuma alteracao foi aplicada." >&2
    echo "Use ./scripts/whatsapp-configure.sh para substituir os wildcards por allowlists/JIDs explicitos." >&2
    exit 1
  fi
}

batch_items=""

append_batch_item() {
  path="$1"
  value_json="$2"

  if [ -n "$batch_items" ]; then
    batch_items="$batch_items,
  {\"path\":\"$path\",\"value\":$value_json}"
  else
    batch_items="  {\"path\":\"$path\",\"value\":$value_json}"
  fi
}

seed_placeholder_if_missing() {
  path="$1"
  value_json="$2"

  if ! config_path_exists "$path"; then
    append_batch_item "$path" "$value_json"
  fi
}

merge_exec_into_tools_deny() {
  tools_deny_json="$(config_get_json tools.deny)"
  compact="$(printf '%s' "$tools_deny_json" | tr -d '\n\r\t ')"

  if [ -z "$compact" ] || [ "$compact" = "null" ]; then
    append_batch_item tools.deny '["exec"]'
    return
  fi

  case "$compact" in
    *\"exec\"*)
      return
      ;;
    \[*\])
      if [ "$compact" = "[]" ]; then
        append_batch_item tools.deny '["exec"]'
        return
      fi

      compact="${compact%]}"
      append_batch_item tools.deny "${compact},\"exec\"]"
      ;;
    *)
      append_batch_item tools.deny '["exec"]'
      ;;
  esac
}

"$compose_cmd" up -d openclaw-gateway >/dev/null

refuse_permissive_wildcards

append_batch_item browser.enabled true
append_batch_item browser.defaultProfile '"openclaw"'
append_batch_item browser.evaluateEnabled false
append_batch_item tools.web.search.enabled true
append_batch_item tools.web.search.provider '"gemini"'
append_batch_item tools.web.fetch.enabled true
append_batch_item tools.elevated.enabled false
append_batch_item channels.whatsapp.dmPolicy '"allowlist"'
append_batch_item channels.whatsapp.groupPolicy '"allowlist"'

merge_exec_into_tools_deny
seed_placeholder_if_missing channels.whatsapp.allowFrom "[\"$placeholder_owner\"]"
seed_placeholder_if_missing channels.whatsapp.groupAllowFrom "[\"$placeholder_owner\"]"
seed_placeholder_if_missing channels.whatsapp.groups "{\"$placeholder_group_jid\":{\"requireMention\":false}}"

batch_json="[
$batch_items
]"

"$compose_cmd" run --rm --no-deps openclaw-cli \
  config set --batch-json "$batch_json" >/dev/null

echo "Perfil aplicado: WhatsApp dedicado + browser."
echo "Pendencias explicitas:"
echo "- substitua $placeholder_owner em channels.whatsapp.allowFrom"
echo "- substitua $placeholder_owner em channels.whatsapp.groupAllowFrom"
echo "- substitua ou remova $placeholder_group_jid em channels.whatsapp.groups e liste so os grupos permitidos com requireMention=false"
echo "- reinicie o gateway depois de ajustar a configuracao persistida"

if [ ! -f "$gemini_secret_file" ]; then
  echo "Aviso: $gemini_secret_file ainda nao existe; web_search=gemini ficara configurado, mas sem chave o runtime nao fara buscas."
fi

if [ "${OPENCLAW_INSTALL_BROWSER:-0}" != "1" ]; then
  echo "Aviso: OPENCLAW_INSTALL_BROWSER!=1 em .env.local; o modo oficial deste perfil pede browser preinstalado na imagem e rebuild."
fi
