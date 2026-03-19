#!/bin/sh
set -eu

project_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
env_file="$project_root/.env.local"
compose_cmd="$project_root/scripts/compose.sh"
placeholder_owner="__PREENCHER_OWNER_E164__"
placeholder_group_jid="__PREENCHER_GROUP_JID__"
blocked_groups_json="{\"$placeholder_group_jid\":{\"requireMention\":false}}"

usage() {
  cat <<'EOF'
Uso: ./scripts/whatsapp-configure.sh

Wrapper guiado para preencher:
- channels.whatsapp.allowFrom
- channels.whatsapp.groupAllowFrom
- channels.whatsapp.groups

Sem editar JSON na mao.
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

trim() {
  printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
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

print_current_json() {
  label="$1"
  value="$2"

  echo "$label"
  if [ -n "$value" ]; then
    printf '%s\n' "$value"
  else
    echo "<ausente>"
  fi
}

read_line_or_exit() {
  if ! IFS= read -r line; then
    echo "Entrada encerrada antes do fim da configuracao guiada." >&2
    exit 1
  fi

  printf '%s\n' "$line"
}

config_get_json() {
  "$compose_cmd" run --rm --no-deps openclaw-cli config get "$1" --json 2>/dev/null || true
}

validate_e164() {
  printf '%s' "$1" | grep -Eq '^\+[1-9][0-9]{7,15}$'
}

validate_group_jid() {
  printf '%s' "$1" | grep -Eq '^[^[:space:]"]+@g\.us$'
}

csv_to_json_array() {
  raw="$1"
  kind="$2"
  old_ifs="$IFS"
  IFS=','
  set -- $raw
  IFS="$old_ifs"

  items=""
  seen="|"
  count=0

  for value in "$@"; do
    trimmed="$(trim "$value")"
    if [ -z "$trimmed" ]; then
      continue
    fi

    case "$kind" in
      e164)
        if ! validate_e164 "$trimmed"; then
          echo "Valor invalido para allowlist WhatsApp: $trimmed" >&2
          echo "Use numeros em formato E.164, por exemplo: +5511999999999" >&2
          return 1
        fi
        ;;
      group_jid)
        if ! validate_group_jid "$trimmed"; then
          echo "JID de grupo invalido: $trimmed" >&2
          echo 'Use o formato real do WhatsApp, por exemplo: 120363012345678901@g.us' >&2
          return 1
        fi
        ;;
      *)
        echo "Tipo de validacao desconhecido: $kind" >&2
        return 1
        ;;
    esac

    case "$seen" in
      *"|$trimmed|"*)
        continue
        ;;
    esac

    seen="$seen$trimmed|"
    escaped="$(json_escape "$trimmed")"

    if [ "$count" -eq 0 ]; then
      items="\"$escaped\""
    else
      items="$items,\"$escaped\""
    fi

    count=$((count + 1))
  done

  if [ "$count" -eq 0 ]; then
    echo "Informe pelo menos um valor valido." >&2
    return 1
  fi

  printf '[%s]\n' "$items"
}

csv_to_groups_json() {
  raw="$1"
  old_ifs="$IFS"
  IFS=','
  set -- $raw
  IFS="$old_ifs"

  items=""
  seen="|"
  count=0

  for value in "$@"; do
    trimmed="$(trim "$value")"
    if [ -z "$trimmed" ]; then
      continue
    fi

    if ! validate_group_jid "$trimmed"; then
      echo "JID de grupo invalido: $trimmed" >&2
      echo 'Use o formato real do WhatsApp, por exemplo: 120363012345678901@g.us' >&2
      return 1
    fi

    case "$seen" in
      *"|$trimmed|"*)
        continue
        ;;
    esac

    seen="$seen$trimmed|"
    escaped="$(json_escape "$trimmed")"
    entry="\"$escaped\":{\"requireMention\":false}"

    if [ "$count" -eq 0 ]; then
      items="$entry"
    else
      items="$items,$entry"
    fi

    count=$((count + 1))
  done

  if [ "$count" -eq 0 ]; then
    echo "Informe pelo menos um JID de grupo valido." >&2
    return 1
  fi

  printf '{%s}\n' "$items"
}

prompt_list_with_current() {
  path_label="$1"
  current_json="$2"
  placeholder="$3"
  kind="$4"
  converted_json=""

  while :; do
    echo
    print_current_json "$path_label atual:" "$current_json"
    if [ "$kind" = "e164" ]; then
      echo "Informe valores em E.164, separados por virgula."
    else
      echo "Informe JIDs de grupo, separados por virgula."
      echo "Digite - para voltar ao bloqueio fail-closed enquanto os JIDs reais ainda nao existem."
    fi

    if [ -n "$current_json" ] && ! contains_text "$current_json" "$placeholder"; then
      echo "Pressione Enter para manter o valor atual."
    fi

    printf "> "
    raw_input="$(read_line_or_exit)"
    raw_input="$(trim "$raw_input")"

    if [ "$kind" = "groups" ] && [ "$raw_input" = "-" ]; then
      printf '%s\n' "$blocked_groups_json"
      return
    fi

    if [ -n "$raw_input" ]; then
      if [ "$kind" = "e164" ]; then
        if converted_json="$(csv_to_json_array "$raw_input" e164)"; then
          printf '%s\n' "$converted_json"
          return
        fi
      else
        if converted_json="$(csv_to_groups_json "$raw_input")"; then
          printf '%s\n' "$converted_json"
          return
        fi
      fi

      echo "Corrija o valor e tente novamente." >&2
      continue
    fi

    if [ -n "$current_json" ] && ! contains_text "$current_json" "$placeholder"; then
      printf '%s\n' "$current_json"
      return
    fi

    if [ "$kind" = "groups" ]; then
      printf '%s\n' "$blocked_groups_json"
      return
    fi

    echo "Nao ha valor atual valido para reaproveitar. Informe ao menos um valor real." >&2
  done
}

prompt_group_allow_from() {
  owner_json="$1"
  current_json="$2"

  while :; do
    echo
    print_current_json "channels.whatsapp.groupAllowFrom atual:" "$current_json"
    echo "Como voce quer configurar quem pode acionar o bot dentro dos grupos allowlisted?"
    echo "1. Usar a mesma allowlist dos owners (recomendado)"

    if [ -n "$current_json" ] && ! contains_text "$current_json" "$placeholder_owner"; then
      echo "2. Manter o valor atual"
      echo "3. Informar outra lista"
    else
      echo "2. Informar outra lista"
    fi

    printf "Escolha [1]: "
    choice="$(read_line_or_exit)"
    choice="$(trim "$choice")"

    if [ -z "$choice" ] || [ "$choice" = "1" ]; then
      printf '%s\n' "$owner_json"
      return
    fi

    if [ -n "$current_json" ] && ! contains_text "$current_json" "$placeholder_owner"; then
      case "$choice" in
        2)
          printf '%s\n' "$current_json"
          return
          ;;
        3)
          prompt_list_with_current "Nova groupAllowFrom" "" "$placeholder_owner" e164
          return
          ;;
      esac
    else
      case "$choice" in
        2)
          prompt_list_with_current "Nova groupAllowFrom" "" "$placeholder_owner" e164
          return
          ;;
      esac
    fi

    echo "Escolha invalida." >&2
  done
}

"$compose_cmd" up -d openclaw-gateway >/dev/null

current_allow_from="$(config_get_json channels.whatsapp.allowFrom)"
current_group_allow_from="$(config_get_json channels.whatsapp.groupAllowFrom)"
current_groups="$(config_get_json channels.whatsapp.groups)"

echo "Configuracao guiada de WhatsApp."
echo "Objetivo: preencher allowlists e grupos sem editar JSON manualmente."

owner_json="$(prompt_list_with_current \
  "channels.whatsapp.allowFrom" \
  "$current_allow_from" \
  "$placeholder_owner" \
  e164)"

group_allow_from_json="$(prompt_group_allow_from "$owner_json" "$current_group_allow_from")"

echo
echo "Para groups:"
echo "- cada grupo informado sera salvo com requireMention=false"
echo "- isso implementa o baseline always-on apenas para os grupos explicitamente listados"
echo "- se voce ainda nao tiver os JIDs, basta pressionar Enter para manter o bloqueio fail-closed"

groups_json="$(prompt_list_with_current \
  "channels.whatsapp.groups" \
  "$current_groups" \
  "$placeholder_group_jid" \
  groups)"

batch_json=$(cat <<EOF
[
  {"path":"channels.whatsapp.allowFrom","value":$owner_json},
  {"path":"channels.whatsapp.groupAllowFrom","value":$group_allow_from_json},
  {"path":"channels.whatsapp.groups","value":$groups_json}
]
EOF
)

echo
echo "Configuracao pronta para aplicar:"
print_current_json "channels.whatsapp.allowFrom ->" "$owner_json"
print_current_json "channels.whatsapp.groupAllowFrom ->" "$group_allow_from_json"
print_current_json "channels.whatsapp.groups ->" "$groups_json"
printf "Aplicar agora? [S/n]: "
confirm="$(read_line_or_exit)"
confirm="$(trim "$confirm")"

case "$confirm" in
  ""|s|S|sim|SIM|Sim)
    ;;
  *)
    echo "Abortado sem alterar a configuracao."
    exit 0
    ;;
esac

"$compose_cmd" run --rm --no-deps openclaw-cli \
  config set --batch-json "$batch_json" --dry-run >/dev/null

"$compose_cmd" run --rm --no-deps openclaw-cli \
  config set --batch-json "$batch_json" >/dev/null

echo
echo "Configuracao WhatsApp atualizada."
echo "Proximo passo recomendado:"
echo "- se ainda nao fez login do canal, rode ./scripts/onboard-whatsapp.sh"
echo "- depois reinicie o gateway para garantir reload completo do processo"
