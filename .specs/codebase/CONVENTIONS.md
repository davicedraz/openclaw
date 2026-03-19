# Code Conventions

## Naming Conventions

**Files:**
Os wrappers e overlays usam `kebab-case`, com helper interno prefixado por underscore.
Examples: `build-sandbox.sh`, `whatsapp-browser-enable.sh`, `_load-runtime-secrets.sh`, `compose.whatsapp-browser.yaml`

**Functions/Methods:**
Funcoes shell usam nomes verbais em lowercase com underscore.
Examples: `load_runtime_secret`, `config_get_json`, `merge_exec_into_tools_deny`, `validate_group_jid`

**Variables:**
Variaveis locais em shell usam `snake_case` minusculo; superficie de configuracao publica usa `OPENCLAW_*`.
Examples: `project_root`, `env_file`, `compose_cmd`, `OPENCLAW_HOST_PORT`, `OPENCLAW_SANDBOX_ENABLE`

**Constants:**
Constantes operacionais tendem a viver como valores de env ou literais pequenos inline.
Examples: `OPENCLAW_IMAGE`, `OPENCLAW_INSTALL_BROWSER`, placeholders `__PREENCHER_OWNER_E164__` e `__PREENCHER_GROUP_JID__`

## Code Organization

**Import/Dependency Declaration:**
Scripts shell quase sempre comecam com:

```sh
#!/bin/sh
set -eu
```

Depois calculam `project_root`, opcionalmente carregam `.env.local`, definem helpers locais e terminam com `exec`.

**File Structure:**
Arquivos simples sao wrappers de 4-6 linhas que apenas delegam para `scripts/compose.sh`.
Arquivos mais complexos seguem esta ordem:

1. `usage` e parse de argumentos
2. carga de `.env.local`
3. helpers de validacao/manipulacao
4. preconditions
5. `exec` final

Examples: `scripts/compose.sh`, `scripts/whatsapp-browser-enable.sh`, `scripts/whatsapp-configure.sh`

## Type Safety/Documentation

**Approach:** seguranca por fail-fast e validacao explicita, nao por tipagem estatica no root

- `set -eu` evita seguir apos erro ou variavel ausente
- validacoes de formato usam `grep -Eq` e helpers dedicados
- mutacoes de config usam `--batch-json` ou `--strict-json` quando possivel
- comentarios sao curtos e explicam o motivo, nao o obvio

## Error Handling

**Pattern:** checar precondicoes cedo, imprimir mensagem curta em `stderr` e sair com codigo nao-zero

Examples:

- `scripts/compose.sh` falha se o Docker socket nao existir quando o sandbox esta habilitado
- `scripts/onboard-telegram.sh` falha cedo se a key principal estiver vazia
- `scripts/whatsapp-browser-enable.sh` recusa aplicar perfil se encontrar wildcards permissivos
- `scripts/whatsapp-configure.sh` re-prompta quando o E.164 ou JID informado e invalido

## Comments/Documentation

**Style:** comentarios explicam alinhamento com o Compose, postura conservadora e comportamento fail-closed

Examples:

- "Mantem o wrapper alinhado com os mesmos valores usados pelo docker compose."
- "So monta o secret Gemini quando o arquivo existe."
- "Sem adivinhar numeros/JIDs do operador."

## Observed Variations

- Wrappers basicos (`up.sh`, `health.sh`, `status.sh`) nao fazem validacao extra e apenas delegam
- Wrappers de configuracao (`sandbox-enable.sh`, `whatsapp-browser-enable.sh`, `whatsapp-configure.sh`) constroem JSON inline em shell
- O root evita dependencias extras; quando precisa de comportamento complexo, delega ao CLI do OpenClaw em vez de duplicar logica
