# Tech Stack

**Analyzed:** 2026-03-19

## Core

- Framework: Docker Compose orquestrando um runtime OpenClaw vendorizado
- Language: POSIX shell no scaffold raiz; TypeScript `5.9.3` no upstream vendorizado
- Runtime: Docker Engine/Compose no host e Node.js `>=22.16.0` dentro da imagem `openclaw:local`
- Package manager: nenhum no root; `vendor/openclaw` usa `pnpm@10.23.0`

## Frontend

- UI Framework: Control UI do OpenClaw servida pelo gateway upstream
- Styling: responsabilidade do upstream vendorizado; o root nao adiciona frontend proprio
- State Management: estado persistido em filesystem (`runtime/config` e `runtime/workspace`)
- Form Handling: onboarding e configuracao da UI sao os do upstream

## Backend

- API Style: gateway local HTTP/WS exposto pelo OpenClaw em `18789` e `18790`
- Database: nenhum banco dedicado no root; persistencia em volumes locais
- Authentication: auth do gateway configurada pelo onboarding/config do OpenClaw e persistida em `runtime/config`

## Testing

- Unit: `vitest@4.1.0` no vendor (`vendor/openclaw/vitest.unit.config.ts`)
- Integration: configs scoped do Vitest para gateway e channels (`vendor/openclaw/vitest.gateway.config.ts`, `vendor/openclaw/vitest.channels.config.ts`)
- E2E: suites `*.e2e.test.ts` no vendor com pool `forks` (`vendor/openclaw/vitest.e2e.config.ts`)

## External Services

- LLM provider principal: OpenAI via Docker secret montado em `/run/secrets/openai_api_key`
- Busca web opcional: Gemini via Docker secret montado em `/run/secrets/gemini_api_key`
- Messaging: Telegram opcional e WhatsApp dedicado como perfil adicional
- Browser automation: Chromium/Xvfb embutidos no upstream quando `OPENCLAW_INSTALL_BROWSER=1`

## Development Tools

- Orquestracao: Docker Compose
- Scripting: `/bin/sh`
- Quality tools no vendor: Vitest, TypeScript, Ruff, Pytest, Oxlint e Oxfmt
- Source boundary: `vendor/openclaw` como snapshot do upstream `openclaw@2026.3.14`
