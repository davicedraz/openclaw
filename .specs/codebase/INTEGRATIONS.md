# External Integrations

## Container Runtime

**Service:** Docker Engine + Docker Compose
**Purpose:** buildar `openclaw:local`, subir `openclaw-gateway` e `openclaw-cli`, e opcionalmente fornecer sandbox Docker para tools
**Implementation:** `compose.yaml`, `compose.sandbox.yaml`, `scripts/compose.sh`, `scripts/build.sh`, `scripts/build-sandbox.sh`
**Configuration:** `.env.local` controla imagem, portas, timezone, bind e toggle de sandbox
**Authentication:** nao ha auth de API propria; o acesso ao Docker socket depende das permissoes do host e do GID detectado em `scripts/compose.sh`

## Upstream Runtime

**Service:** OpenClaw vendorizado (`openclaw@2026.3.14`)
**Purpose:** executar gateway, CLI, dashboard, TUI, browser e integracoes de canal
**Implementation:** imagem buildada a partir de `vendor/openclaw`, com `node dist/index.js` acionado pelos entrypoints locais
**Configuration:** `runtime/config`, `runtime/workspace` e comandos `openclaw-cli config get/set`
**Authentication:** configurada pelo onboarding do proprio OpenClaw e persistida em `runtime/config`

## LLM Providers

### OpenAI

**Purpose:** provider principal do runtime
**Location:** `compose.yaml`, `scripts/_load-runtime-secrets.sh`, `scripts/onboard-telegram.sh`, `secrets/README.md`
**Authentication:** `secrets/openai_api_key.txt` montado como Docker secret em `/run/secrets/openai_api_key`
**Key endpoints:** responsabilidade do upstream; o root apenas injeta o secret

### Gemini

**Purpose:** `tools.web.search` no perfil WhatsApp dedicado + browser
**Location:** `compose.whatsapp-browser.yaml`, `scripts/whatsapp-browser-enable.sh`, `docs/whatsapp-dedicado-browser.md`
**Authentication:** `secrets/gemini_api_key.txt` montado como Docker secret em `/run/secrets/gemini_api_key`
**Key endpoints:** responsabilidade do upstream; o root apenas habilita o provider na config

## Messaging Channels

### Telegram

**Purpose:** canal opcional posterior ao bootstrap local
**Location:** `scripts/onboard-telegram.sh`, `docs/telegram-onboarding.md`
**Authentication:** key do provider + token do bot configurados via onboarding do OpenClaw
**Key endpoints:** responsabilidade do upstream; o root nao implementa cliente Telegram proprio

### WhatsApp

**Purpose:** perfil oficial adicional para um agente mais autonomo com numero dedicado
**Location:** `scripts/onboard-whatsapp.sh`, `scripts/whatsapp-browser-enable.sh`, `scripts/whatsapp-configure.sh`, `docs/whatsapp-dedicado-browser.md`
**Authentication:** QR login via `openclaw channels login --channel whatsapp`, persistido em `runtime/config`
**Key endpoints:** responsabilidade do upstream; o root apenas endurece policies, allowlists e grupos

## Browser Automation

**Service:** browser gerenciado pelo OpenClaw com perfil `openclaw`
**Purpose:** habilitar automacao web no perfil WhatsApp dedicado mantendo `evaluateEnabled=false`
**Implementation:** build arg `OPENCLAW_INSTALL_BROWSER`, config `browser.enabled`, `browser.defaultProfile` e `browser.evaluateEnabled`
**Configuration:** `.env.local`, `scripts/whatsapp-browser-enable.sh`, `docs/whatsapp-dedicado-browser.md`
**Authentication:** sessao e credenciais do browser ficam do lado do runtime upstream e devem ser tratadas como sensiveis

## Background Jobs

**Queue system:** nenhum sistema de fila definido no root
**Location:** o runtime pode persistir jobs em `runtime/config/cron/`, mas o scaffold nao define jobs como codigo
**Jobs:** a postura atual recomenda jobs `isolated` e sem entrega automatica ampla por padrao
