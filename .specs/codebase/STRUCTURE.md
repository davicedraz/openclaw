# Project Structure

**Root:** `/Users/davicedraz/Development/openclaw-personal-gateway`

## Directory Tree

```text
.
├── .agents/
│   └── skills/
├── .codex/
│   └── skills/
├── .specs/
│   ├── codebase/
│   ├── features/
│   ├── project/
│   └── quick/
├── docs/
│   ├── plans/
│   ├── telegram-onboarding.md
│   └── whatsapp-dedicado-browser.md
├── runtime/
│   ├── config/
│   └── workspace/
├── scripts/
├── secrets/
└── vendor/
    └── openclaw/
```

## Module Organization

### Project memory and planning

**Purpose:** guardar visao, roadmap, memoria viva e mapeamento do codebase usando `tlc-spec-driven`
**Location:** `.specs/project/`, `.specs/codebase/`, `.specs/features/` e `.specs/quick/`
**Key files:** `.specs/project/PROJECT.md`, `.specs/project/ROADMAP.md`, `.specs/project/STATE.md`, `.specs/features/README.md`, `.specs/quick/README.md`

### Runtime orchestration

**Purpose:** construir a imagem local, montar secrets, aplicar overlays e subir os containers corretos
**Location:** raiz do repo + `scripts/`
**Key files:** `compose.yaml`, `compose.sandbox.yaml`, `compose.whatsapp-browser.yaml`, `scripts/compose.sh`, `scripts/gateway-entrypoint.sh`, `scripts/cli-entrypoint.sh`

### Operator workflows

**Purpose:** expor uma UX operacional curta para build, logs, status, onboarding e configuracao
**Location:** `scripts/`
**Key files:** `scripts/build.sh`, `scripts/up.sh`, `scripts/health.sh`, `scripts/status.sh`, `scripts/tui.sh`, `scripts/dashboard.sh`, `scripts/sandbox-enable.sh`, `scripts/whatsapp-browser-enable.sh`, `scripts/whatsapp-configure.sh`

### Runbooks and normative docs

**Purpose:** explicar setup, operacao e caminhos oficiais do scaffold
**Location:** `README.md`, `docs/`, `AGENTS.md`
**Key files:** `README.md`, `docs/notes.md`, `docs/telegram-onboarding.md`, `docs/whatsapp-dedicado-browser.md`, `AGENTS.md`

### Sensitive local state

**Purpose:** persistir segredos e estado do runtime fora do codigo versionado
**Location:** `secrets/` e `runtime/`
**Key files:** `secrets/README.md`, `runtime/config/`, `runtime/workspace/`

### Vendored upstream

**Purpose:** fornecer o runtime real do OpenClaw sem depender de install externo no host
**Location:** `vendor/openclaw/`
**Key files:** `vendor/openclaw/package.json`, `vendor/openclaw/Dockerfile`, `vendor/openclaw/README.md`

## Where Things Live

**Gateway runtime bootstrap:**

- UI/Interface: `README.md`, `docs/telegram-onboarding.md`, `docs/whatsapp-dedicado-browser.md`
- Business Logic: `scripts/gateway-entrypoint.sh`, `scripts/compose.sh`
- Data Access: `runtime/config`, `runtime/workspace`
- Configuration: `.env.local`, `compose.yaml`, overlays `compose.*.yaml`

**Local operator workflows:**

- UI/Interface: wrappers em `scripts/` e dashboard servida pelo gateway
- Business Logic: `scripts/up.sh`, `scripts/health.sh`, `scripts/status.sh`, `scripts/logs.sh`, `scripts/docker-logs.sh`, `scripts/tui.sh`, `scripts/dashboard.sh`
- Data Access: `runtime/config`, `runtime/workspace`
- Configuration: `.env.local`

**Channel profiles:**

- UI/Interface: `docs/telegram-onboarding.md`, `docs/whatsapp-dedicado-browser.md`
- Business Logic: `scripts/onboard-telegram.sh`, `scripts/onboard-whatsapp.sh`, `scripts/whatsapp-browser-enable.sh`, `scripts/whatsapp-configure.sh`
- Data Access: `runtime/config`
- Configuration: `compose.whatsapp-browser.yaml`, OpenClaw config persistida

## Special Directories

**`runtime/`:**
**Purpose:** guardar estado vivo do runtime; deve ser tratado como sensivel
**Examples:** `runtime/config/`, `runtime/workspace/`

**`vendor/openclaw/`:**
**Purpose:** boundary com o upstream; evitar exploracao/refactor por padrao
**Examples:** `vendor/openclaw/package.json`, `vendor/openclaw/Dockerfile`, `vendor/openclaw/scripts/`
