# Testing Infrastructure

## Test Frameworks

**Unit/Integration:** o scaffold raiz nao possui framework automatizado proprio; o vendor usa `vitest@4.1.0`
**E2E:** o vendor usa Vitest para suites `*.e2e.test.ts` com `pool: "forks"` em `vendor/openclaw/vitest.e2e.config.ts`
**Coverage:** `@vitest/coverage-v8` declarado em `vendor/openclaw/package.json`

## Test Organization

**Location:** o root depende de smoke checks manuais em `scripts/`; os testes automatizados vivem no vendor
**Naming:** `*.test.ts` e `*.e2e.test.ts`
**Structure:** configs Vitest separados por concern (`unit`, `gateway`, `channels`, `e2e`)

## Testing Patterns

### Unit Tests

**Approach:** testes pontuais no vendor cobrindo utilitarios, modulos e componentes do runtime
**Location:** `vendor/openclaw/src/**/*.test.ts`, `vendor/openclaw/extensions/**/*.test.ts`
**Observed pattern:** o root nao replica essa abordagem para os wrappers shell

### Integration Tests

**Approach:** suites scoped por area do runtime e checks manuais via CLI/Docker no scaffold local
**Location:** `vendor/openclaw/vitest.gateway.config.ts`, `vendor/openclaw/vitest.channels.config.ts`, `scripts/health.sh`, `scripts/status.sh`, `scripts/sandbox-explain.sh`
**Observed pattern:** integracoes do root sao verificadas por comportamento do gateway e do CLI, nao por mocks locais

### E2E Tests

**Approach:** suites deterministicas com processo isolado e numero baixo de workers por default
**Location:** `vendor/openclaw/test/**/*.e2e.test.ts`, `vendor/openclaw/src/**/*.e2e.test.ts`, `vendor/openclaw/extensions/**/*.e2e.test.ts`
**Observed pattern:** o upstream prioriza isolamento para reduzir vazamento de estado entre casos

## Test Execution

**Commands:**

- Manual smoke no root: `./scripts/up.sh`, `./scripts/health.sh`, `./scripts/status.sh`, `./scripts/docker-logs.sh`, `./scripts/sandbox-explain.sh`
- Vendor unit: `pnpm exec vitest run --config vitest.unit.config.ts`
- Vendor gateway: `pnpm exec vitest run --config vitest.gateway.config.ts`
- Vendor channels: `pnpm exec vitest run --config vitest.channels.config.ts`
- Vendor e2e: `pnpm exec vitest run --config vitest.e2e.config.ts`
- Vendor UI: `pnpm lint:ui:no-raw-window-open && pnpm --dir ui test`

**Configuration:** os testes automatizados do upstream devem ser rodados a partir de `vendor/openclaw`; os smoke checks do root dependem de Docker local e da configuracao atual em `.env.local`

## Coverage Targets

**Current:** nao ha meta formal de cobertura no root do projeto
**Goals:** adicionar ao menos smoke coverage automatizada para wrappers shell e overlays de Compose mais criticos
**Enforcement:** nenhuma no root; o vendor tem ferramentas e suites dedicadas, mas o scaffold local ainda depende de validacao manual

## Test Coverage Gaps

**Shell wrappers do root:**

- What's not tested: `scripts/compose.sh`, `scripts/sandbox-enable.sh`, `scripts/whatsapp-browser-enable.sh`, `scripts/whatsapp-configure.sh`
- Risk: regressao operacional detectada apenas depois de subir container ou escrever config persistida
- Priority: High
- Difficulty to test: Media, porque dependem de Docker, arquivos locais e estado do runtime
