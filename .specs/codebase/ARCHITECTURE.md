# Architecture

**Pattern:** Scaffold operacional fino em volta de um runtime upstream vendorizado

## High-Level Structure

```text
shell do operador
  -> wrappers em scripts/
    -> scripts/compose.sh
      -> compose.yaml + overlays opcionais
        -> openclaw-gateway + openclaw-cli
          -> runtime/config + runtime/workspace
          -> Docker secrets montados em /run/secrets/*
          -> runtime OpenClaw vendorizado em vendor/openclaw
```

O projeto nao tenta reimplementar o OpenClaw. Ele adiciona um envelope operacional local para build, subida, onboarding, endurecimento e runbooks.

## Identified Patterns

### Wrapper-first orchestration

**Location:** `scripts/*.sh`, `compose.yaml`, `compose.sandbox.yaml`, `compose.whatsapp-browser.yaml`
**Purpose:** dar uma interface curta e consistente para todas as operacoes do runtime
**Implementation:** wrappers pequenos delegam para `scripts/compose.sh`, que carrega `.env.local`, detecta overlays opcionais e executa `docker compose`
**Example:** `scripts/up.sh`, `scripts/health.sh`, `scripts/status.sh`, `scripts/compose.sh`

### Runtime secret injection

**Location:** `compose.yaml`, `compose.whatsapp-browser.yaml`, `scripts/_load-runtime-secrets.sh`, `scripts/gateway-entrypoint.sh`, `scripts/cli-entrypoint.sh`
**Purpose:** manter chaves fora do codigo versionado e ainda assim expor `OPENAI_API_KEY` e `GEMINI_API_KEY` ao processo Node
**Implementation:** o Compose monta arquivos locais como Docker secrets e os entrypoints shell exportam variaveis de ambiente apenas quando os arquivos montados existem e nao estao vazios
**Example:** `openai_api_key` em `compose.yaml` e `load_runtime_secret` em `scripts/_load-runtime-secrets.sh`

### Upstream boundary with local customization

**Location:** `vendor/openclaw/` versus `compose*.yaml`, `scripts/`, `docs/`
**Purpose:** preservar proximidade com o fluxo oficial do OpenClaw enquanto o repo local concentra customizacoes operacionais
**Implementation:** a imagem nasce do vendor, mas o bind, os volumes, os secrets, as politicas iniciais e os runbooks vivem no root
**Example:** `compose.yaml` builda `./vendor/openclaw`, enquanto `scripts/gateway-entrypoint.sh` adiciona `--allow-unconfigured`

### Fail-closed channel hardening

**Location:** `scripts/sandbox-enable.sh`, `scripts/whatsapp-browser-enable.sh`, `scripts/whatsapp-configure.sh`
**Purpose:** aplicar baselines conservadores sem depender de edicao manual de JSON complexo
**Implementation:** wrappers sobem o gateway se necessario e usam `openclaw-cli config set --batch-json` para gravar configuracao persistida, recusando wildcards permissivos e sem inventar owners/JIDs reais
**Example:** `scripts/whatsapp-browser-enable.sh` adiciona `exec` em `tools.deny` e semeia placeholders fail-closed

## Data Flow

### Gateway boot flow

1. O operador chama `./scripts/up.sh`.
2. `scripts/up.sh` delega para `scripts/compose.sh up -d openclaw-gateway`.
3. `scripts/compose.sh` carrega `.env.local`, avalia overlays opcionais e invoca `docker compose`.
4. O container `openclaw-gateway` entra pelo `scripts/gateway-entrypoint.sh`.
5. O entrypoint carrega secrets montados e executa `node dist/index.js gateway --allow-unconfigured`.

### Secret loading flow

1. O arquivo local vive em `secrets/openai_api_key.txt` ou `secrets/gemini_api_key.txt`.
2. O Compose monta o arquivo como Docker secret dentro do container.
3. `scripts/_load-runtime-secrets.sh` le o arquivo montado e exporta a variavel de ambiente correspondente.
4. O runtime Node passa a enxergar `OPENAI_API_KEY` ou `GEMINI_API_KEY` sem que o valor apareca em `compose.yaml`.

### Config mutation flow

1. Um wrapper de hardening sobe o gateway se necessario.
2. O wrapper roda `openclaw-cli config set` dentro de `openclaw-cli`.
3. A configuracao persistida vai para `runtime/config`.
4. O gateway precisa ser reiniciado ou reenxergar a configuracao para operar com os novos valores.

### Operator interaction flow

1. `health`, `status`, `logs`, `tui` e `dashboard` entram pelo container `openclaw-cli`.
2. `openclaw-cli` usa `network_mode: service:openclaw-gateway`, entao compartilha a rede do gateway.
3. O operador interage com o runtime sem precisar instalar o CLI no host.

## Code Organization

**Approach:** organizacao por boundary operacional, nao por dominio de negocio

**Structure:**

- Root: docs, Compose files, wrappers shell e memoria do projeto
- `scripts/`: interface operacional do scaffold
- `docs/`: runbooks e notas de produto/seguranca
- `runtime/`: estado persistido do runtime
- `secrets/`: arquivos locais sensiveis fora do versionamento
- `vendor/openclaw/`: runtime upstream vendorizado

**Module boundaries:**

- O root decide como construir, subir, endurecer e operar
- O vendor decide como o gateway, CLI, UI, browser e canais funcionam internamente
- `.specs/` documenta contexto e planejamento sem alterar o runtime
